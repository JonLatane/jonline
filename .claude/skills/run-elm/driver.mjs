#!/usr/bin/env node
// Minimal chromium-cli-style REPL driver for the Elm SPA (frontends/elm-spa),
// for containers where chromium-cli itself isn't available. See SKILL.md's
// "Screenshot / drive a page" section for the exact setup + usage.
//
// Reads one command per line from a script file (arg 1) or stdin, in order,
// against a single persistent page. Commands:
//
//   nav <url>                    navigate
//   wait-for text=<text>         wait for text to appear anywhere on the page
//   wait-for <css selector>      wait for a selector (Playwright syntax, so
//                                 `button:has-text("Theme")` works too)
//   click <selector>
//   fill <selector> <value...>   rest of the line is the value
//   press <key>                  e.g. Enter
//   sleep <ms>
//   screenshot <path>            defaults to screenshot.png
//   console-errors               prints any page console.error()s seen so far
//
// Example:
//   node driver.mjs <<'EOF'
//   nav http://localhost:1234/server/http:localhost
//   wait-for text=About
//   click button:has-text("Theme")
//   screenshot theme.png
//   console-errors
//   EOF

import { chromium } from "playwright";
import { readFileSync } from "node:fs";

const scriptPath = process.argv[2];
const rawScript = scriptPath
  ? readFileSync(scriptPath, "utf8")
  : readFileSync(0, "utf8");

const lines = rawScript
  .split("\n")
  .map((line) => line.trim())
  .filter((line) => line.length > 0 && !line.startsWith("#"));

const consoleErrors = [];

function splitFirst(rest) {
  const idx = rest.indexOf(" ");
  return idx === -1 ? [rest, ""] : [rest.slice(0, idx), rest.slice(idx + 1)];
}

async function main() {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1000, height: 900 } });
  page.on("console", (msg) => {
    if (msg.type() === "error") consoleErrors.push(msg.text());
  });
  page.on("pageerror", (err) => consoleErrors.push(String(err)));

  for (const line of lines) {
    const [cmd, rest] = splitFirst(line);
    console.log(`> ${line}`);
    try {
      switch (cmd) {
        case "nav":
          await page.goto(rest, { waitUntil: "networkidle" });
          break;

        case "wait-for":
          if (rest.startsWith("text=")) {
            await page.getByText(rest.slice(5)).first().waitFor({ timeout: 15000 });
          } else {
            await page.waitForSelector(rest, { timeout: 15000 });
          }
          break;

        case "click":
          await page.click(rest, { timeout: 15000 });
          break;

        case "fill": {
          const [selector, value] = splitFirst(rest);
          await page.fill(selector, value);
          break;
        }

        case "press":
          await page.keyboard.press(rest);
          break;

        case "sleep":
          await page.waitForTimeout(parseInt(rest, 10) || 500);
          break;

        case "screenshot":
          await page.screenshot({ path: rest || "screenshot.png" });
          break;

        case "console-errors":
          console.log(JSON.stringify(consoleErrors, null, 2));
          break;

        default:
          console.error(`unknown command: ${cmd}`);
      }
    } catch (err) {
      console.error(`command failed: ${line}\n${err}`);
    }
  }

  await browser.close();
}

main();
