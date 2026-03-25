#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <imm.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <stdlib.h>

#pragma comment(lib, "imm32.lib")
#pragma comment(lib, "user32.lib")

static int g_debug = 0;

static void print_usage(const char *prog)
{
    fprintf(stderr, "usage: %s <off|on|status> [--debug]\n", prog);
}

static void debug_log(const char *fmt, ...)
{
    va_list ap;
    if (!g_debug) {
        return;
    }
    fprintf(stderr, "imectl[debug]: ");
    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap);
    fputc('\n', stderr);
}

static void debug_last_error(const char *label)
{
    DWORD err = GetLastError();
    if (err == 0) {
        debug_log("%s failed (GetLastError=0)", label);
        return;
    }

    {
        char msg[256] = {0};
        DWORD len = FormatMessageA(
            FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
            NULL,
            err,
            0,
            msg,
            (DWORD)sizeof(msg),
            NULL
        );
        if (len > 0) {
            while (len > 0 && (msg[len - 1] == '\r' || msg[len - 1] == '\n')) {
                msg[len - 1] = '\0';
                len--;
            }
            debug_log("%s failed (err=%lu: %s)", label, (unsigned long)err, msg);
            return;
        }
    }

    debug_log("%s failed (err=%lu)", label, (unsigned long)err);
}

static void debug_window_info(const char *label, HWND hwnd)
{
    char cls[128] = {0};
    DWORD pid = 0;
    DWORD tid = 0;
    int n = 0;

    if (!g_debug) {
        return;
    }

    if (hwnd == NULL) {
        debug_log("%s: hwnd=NULL", label);
        return;
    }

    tid = GetWindowThreadProcessId(hwnd, &pid);
    n = GetClassNameA(hwnd, cls, (int)sizeof(cls));
    if (n <= 0) {
        strcpy_s(cls, sizeof(cls), "(unknown)");
    }

    debug_log("%s: hwnd=%p class=%s tid=%lu pid=%lu",
        label,
        (void *)hwnd,
        cls,
        (unsigned long)tid,
        (unsigned long)pid
    );
}

static int debug_enabled_from_env(void)
{
    const char *v = getenv("IMECTL_DEBUG");
    if (v == NULL || v[0] == '\0') {
        return 0;
    }
    return strcmp(v, "0") != 0;
}

static HWND get_target_window(void)
{
    HWND fg = GetForegroundWindow();
    DWORD tid = 0;
    GUITHREADINFO gti;

    debug_window_info("foreground", fg);
    if (fg == NULL) {
        return NULL;
    }

    tid = GetWindowThreadProcessId(fg, NULL);
    ZeroMemory(&gti, sizeof(gti));
    gti.cbSize = sizeof(gti);

    if (!GetGUIThreadInfo(tid, &gti)) {
        debug_last_error("GetGUIThreadInfo");
        return fg;
    }

    debug_window_info("gti.hwndActive", gti.hwndActive);
    debug_window_info("gti.hwndFocus", gti.hwndFocus);
    if (gti.hwndFocus != NULL) {
        return gti.hwndFocus;
    }

    return fg;
}

static int acquire_context(HWND target, HIMC *out_himc, HWND *out_hwnd)
{
    HWND candidates[3] = {0};
    int count = 0;
    int i;

    HWND root = target ? GetAncestor(target, GA_ROOT) : NULL;
    HWND fg = GetForegroundWindow();

    if (target != NULL) {
        candidates[count++] = target;
    }
    if (root != NULL && root != target) {
        candidates[count++] = root;
    }
    if (fg != NULL && fg != target && fg != root) {
        candidates[count++] = fg;
    }

    for (i = 0; i < count; i++) {
        HIMC himc = ImmGetContext(candidates[i]);
        debug_window_info("context candidate", candidates[i]);
        debug_log("ImmGetContext(%p) -> %p", (void *)candidates[i], (void *)himc);
        debug_log("ImmGetDefaultIMEWnd(%p) -> %p",
            (void *)candidates[i],
            (void *)ImmGetDefaultIMEWnd(candidates[i])
        );

        if (himc != NULL) {
            *out_himc = himc;
            *out_hwnd = candidates[i];
            return 0;
        }
    }

    fprintf(stderr, "imectl: IME context not found\n");
    return 1;
}

static int get_open_status(HWND hwnd, BOOL *is_open)
{
    HIMC himc = NULL;
    HWND ctx_hwnd = NULL;

    if (acquire_context(hwnd, &himc, &ctx_hwnd) != 0) {
        return 1;
    }

    *is_open = ImmGetOpenStatus(himc);
    debug_log("ImmGetOpenStatus(%p) -> %d", (void *)himc, *is_open ? 1 : 0);
    ImmReleaseContext(ctx_hwnd, himc);
    return 0;
}

static int set_open_status(HWND hwnd, BOOL is_open)
{
    HIMC himc = NULL;
    HWND ctx_hwnd = NULL;
    BOOL current = FALSE;

    if (acquire_context(hwnd, &himc, &ctx_hwnd) != 0) {
        return 1;
    }

    if (!ImmSetOpenStatus(himc, is_open)) {
        fprintf(stderr, "imectl: failed to request IME %s\n", is_open ? "on" : "off");
        ImmReleaseContext(ctx_hwnd, himc);
        return 1;
    }
    debug_log("ImmSetOpenStatus(%p, %d) succeeded", (void *)himc, is_open ? 1 : 0);

    current = ImmGetOpenStatus(himc);
    debug_log("ImmGetOpenStatus(%p) after set -> %d", (void *)himc, current ? 1 : 0);
    ImmReleaseContext(ctx_hwnd, himc);

    if (!!current != !!is_open) {
        fprintf(stderr, "imectl: failed to switch IME %s\n", is_open ? "on" : "off");
        return 1;
    }

    return 0;
}

int main(int argc, char **argv)
{
    const char *command = NULL;
    HWND hwnd;
    int i;

    if (argc < 2 || argc > 3) {
        print_usage(argv[0]);
        return 2;
    }

    g_debug = debug_enabled_from_env();
    for (i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--debug") == 0) {
            g_debug = 1;
            continue;
        }
        if (command == NULL) {
            command = argv[i];
            continue;
        }

        print_usage(argv[0]);
        return 2;
    }

    if (command == NULL) {
        print_usage(argv[0]);
        return 2;
    }

    hwnd = get_target_window();
    if (hwnd == NULL) {
        fprintf(stderr, "imectl: active window not found\n");
        return 1;
    }
    debug_window_info("selected target", hwnd);

    if (strcmp(command, "off") == 0) {
        return set_open_status(hwnd, FALSE);
    }

    if (strcmp(command, "on") == 0) {
        return set_open_status(hwnd, TRUE);
    }

    if (strcmp(command, "status") == 0) {
        BOOL is_open = FALSE;
        if (get_open_status(hwnd, &is_open) != 0) {
            return 1;
        }
        puts(is_open ? "on" : "off");
        return 0;
    }

    print_usage(argv[0]);
    return 2;
}
