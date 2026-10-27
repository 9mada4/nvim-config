const crypto = require("node:crypto")
const fs = require("node:fs/promises")
const path = require("node:path")

const version = "11.17.2"
const expectedSha256 = "581ed7d74bd9048d0e3a91363927d72ef22942d7722546b27f7cc29e35390eb8"
const assetPath = process.argv[2]

if (!assetPath) {
  console.error("Usage: node install-markdown-preview-mermaid.cjs <mermaid.min.js path>")
  process.exit(2)
}

async function main() {
  const url = `https://cdn.jsdelivr.net/npm/mermaid@${version}/dist/mermaid.min.js`
  const response = await fetch(url)
  if (!response.ok) {
    throw new Error(`Download failed (${response.status} ${response.statusText})`)
  }

  const contents = Buffer.from(await response.arrayBuffer())
  const actualSha256 = crypto.createHash("sha256").update(contents).digest("hex")
  if (actualSha256 !== expectedSha256) {
    throw new Error(`SHA-256 mismatch for Mermaid ${version}: ${actualSha256}`)
  }

  const absolutePath = path.resolve(assetPath)
  const temporaryPath = `${absolutePath}.${process.pid}.tmp`
  const currentMode = await fs.stat(absolutePath).then((stat) => stat.mode & 0o777).catch(() => 0o644)
  await fs.writeFile(temporaryPath, contents, { mode: currentMode })
  await fs.rename(temporaryPath, absolutePath)
  console.log(`Installed Mermaid ${version} in ${absolutePath}`)
}

main().catch((error) => {
  console.error(error.message)
  process.exitCode = 1
})
