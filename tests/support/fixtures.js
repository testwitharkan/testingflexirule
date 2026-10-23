const fs = require("fs");
const path = require("path");
const { test: base, expect } = require("@playwright/test");
const { createRule, deleteRule } = require("./frappe");

const test = base.extend({
  page: async ({ page }, use, testInfo) => {
    const pageErrors = [];
    const consoleErrors = [];
    const failedRequests = [];

    page.on("pageerror", (error) => pageErrors.push(error.stack || error.message));
    page.on("console", (message) => {
      if (message.type() === "error") {
        consoleErrors.push(message.text());
      }
    });
    page.on("requestfailed", (request) => {
      failedRequests.push({
        url: request.url(),
        error: request.failure()?.errorText || "request failed",
      });
    });

    await use(page);

    const diagnostics = { pageErrors, consoleErrors, failedRequests };
    await testInfo.attach("browser-diagnostics.json", {
      body: Buffer.from(JSON.stringify(diagnostics, null, 2)),
      contentType: "application/json",
    });

    if (process.env.CAPTURE_SCREENSHOTS === "1" && !page.isClosed()) {
      const screenshotsDir = path.resolve(process.cwd(), "screenshots/generated");
      fs.mkdirSync(screenshotsDir, { recursive: true });
      const safeTitle = testInfo.title.replace(/[^a-z0-9_-]+/gi, "_").slice(0, 100);
      const filePath = path.join(
        screenshotsDir,
        safeTitle + "_retry-" + testInfo.retry + ".png"
      );
      try {
        await page.screenshot({ path: filePath, fullPage: true, animations: "disabled" });
        await testInfo.attach("requested-page-screenshot", {
          path: filePath,
          contentType: "image/png",
        });
      } catch (error) {
        await testInfo.attach("screenshot-capture-error.txt", {
          body: Buffer.from(String(error)),
          contentType: "text/plain",
        });
      }
    }

    if (pageErrors.length && testInfo.status === "passed") {
      throw new Error(
        "Uncaught browser JavaScript error(s) were observed:\n" +
        pageErrors.map((item, index) => (index + 1) + ". " + item).join("\n")
      );
    }

    if (process.env.FAIL_ON_CONSOLE_ERRORS === "1" &&
        consoleErrors.length &&
        testInfo.status === "passed") {
      throw new Error(
        "Browser console error(s) were observed:\n" +
        consoleErrors.map((item, index) => (index + 1) + ". " + item).join("\n")
      );
    }
  },

  testRules: async ({ page }, use) => {
    const createdNames = new Set();
    const rules = {
      create: async (overrides = {}) => {
        const doc = await createRule(page, overrides);
        if (doc && doc.name) createdNames.add(doc.name);
        return doc;
      },
      track: (name) => {
        if (name) createdNames.add(name);
      },
    };

    await use(rules);

    for (const name of createdNames) {
      try {
        await deleteRule(page, name);
      } catch (error) {
        console.warn("Could not clean up temporary inactive Rule " + name + ": " + error);
      }
    }
  },
});

module.exports = { test, expect };