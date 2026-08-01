import { chromium } from "playwright";

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 360, height: 800 } });

await page.goto("http://localhost:1234", { waitUntil: "networkidle" });
await page.waitForSelector(".accounts-menu-toggle");
await page.click(".accounts-menu-toggle");
await page.waitForSelector("#account-form-server");
await page.fill("#account-form-username", "narrowvistest1");
await page.click('button:has-text("Create Account")');
await page.waitForSelector("#account-form-password");
await page.keyboard.type("SomeP4ssword123", { delay: 20 });
await page.waitForSelector("text=Media Policy");
await page.click('button:has-text("Cancel")');
await page.waitForTimeout(300);
await page.click('button[type="submit"]');
await page.waitForSelector("text=Media Policy");
await page.waitForTimeout(500);
await page.click('.create-account-modal button:has-text("Create Account")');
await page.waitForTimeout(2500);
await page.click('body', { position: { x: 5, y: 400 } });
await page.waitForTimeout(300);
await page.click('button[title="Create New"]');
await page.waitForSelector(".create-new-panel-visibility-select");
await page.screenshot({ path: "/private/tmp/claude-501/-Users-jonlatane-Development-jonline/29c805e4-32d4-4649-a7b3-5ffe794fe304/scratchpad/narrow_post_mode.png" });
await page.click('.create-new-panel-tab:has-text("New Event")');
await page.waitForTimeout(300);
await page.screenshot({ path: "/private/tmp/claude-501/-Users-jonlatane-Development-jonline/29c805e4-32d4-4649-a7b3-5ffe794fe304/scratchpad/narrow_event_mode.png" });

await browser.close();
