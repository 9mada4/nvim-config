#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <imm.h>
#include <stdio.h>
#include <string.h>

#pragma comment(lib, "imm32.lib")

static void print_usage(const char *prog)
{
    fprintf(stderr, "usage: %s <off|on|status>\n", prog);
}

static HWND get_target_window(void)
{
    return GetForegroundWindow();
}

static int get_open_status(HWND hwnd, BOOL *is_open)
{
    HIMC himc = ImmGetContext(hwnd);
    if (himc == NULL) {
        fprintf(stderr, "imectl: IME context not found\n");
        return 1;
    }

    *is_open = ImmGetOpenStatus(himc);
    ImmReleaseContext(hwnd, himc);
    return 0;
}

static int set_open_status(HWND hwnd, BOOL is_open)
{
    HIMC himc = ImmGetContext(hwnd);
    BOOL current = FALSE;

    if (himc == NULL) {
        fprintf(stderr, "imectl: IME context not found\n");
        return 1;
    }

    if (!ImmSetOpenStatus(himc, is_open)) {
        fprintf(stderr, "imectl: failed to request IME %s\n", is_open ? "on" : "off");
        ImmReleaseContext(hwnd, himc);
        return 1;
    }

    current = ImmGetOpenStatus(himc);
    ImmReleaseContext(hwnd, himc);

    if (!!current != !!is_open) {
        fprintf(stderr, "imectl: failed to switch IME %s\n", is_open ? "on" : "off");
        return 1;
    }

    return 0;
}

int main(int argc, char **argv)
{
    HWND hwnd;

    if (argc != 2) {
        print_usage(argv[0]);
        return 2;
    }

    hwnd = get_target_window();
    if (hwnd == NULL) {
        fprintf(stderr, "imectl: active window not found\n");
        return 1;
    }

    if (strcmp(argv[1], "off") == 0) {
        return set_open_status(hwnd, FALSE);
    }

    if (strcmp(argv[1], "on") == 0) {
        return set_open_status(hwnd, TRUE);
    }

    if (strcmp(argv[1], "status") == 0) {
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
