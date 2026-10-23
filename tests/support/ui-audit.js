const fs = require("fs");
const path = require("path");
const { expect } = require("./fixtures");

async function auditLayout(page, testInfo, pageName) {
  const measurements = await page.evaluate((pageName) => {
    const selectors = [
      "body",
      ".navbar",
      ".workspace-header",
      ".layout-main-section",
      ".rule-builder-container",
      ".builder-main",
      ".canvas-container",
      ".sidebar-container",
      ".vue-flow",
      ".controls-panel",
      ".configuration-panel",
      ".list-row-container",
      ".config-modal-container",
    ];
    const elements = {};

    for (const selector of selectors) {
      const element = document.querySelector(selector);
      if (!element) {
        elements[selector] = null;
        continue;
      }

      const rect = element.getBoundingClientRect();
      const style = window.getComputedStyle(element);
      elements[selector] = {
        x: Math.round(rect.x * 100) / 100,
        y: Math.round(rect.y * 100) / 100,
        width: Math.round(rect.width * 100) / 100,
        height: Math.round(rect.height * 100) / 100,
        right: Math.round(rect.right * 100) / 100,
        bottom: Math.round(rect.bottom * 100) / 100,
        display: style.display,
        position: style.position,
        overflowX: style.overflowX,
        overflowY: style.overflowY,
        fontSize: style.fontSize,
        lineHeight: style.lineHeight,
        color: style.color,
        backgroundColor: style.backgroundColor,
      };
    }

    return {
      timestamp: new Date().toISOString(),
      pageName,
      url: window.location.href,
      viewport: { width: window.innerWidth, height: window.innerHeight },
      document: {
        clientWidth: document.documentElement.clientWidth,
        scrollWidth: document.documentElement.scrollWidth,
        horizontalOverflow: Math.max(
          0,
          document.documentElement.scrollWidth - document.documentElement.clientWidth
        ),
        bodyScrollWidth: document.body ? document.body.scrollWidth : null,
      },
      elements,
    };
  }, pageName);

  const outputPath = path.resolve(process.cwd(), "reports/generated/layout-audit.json");
  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  let existing = [];
  if (fs.existsSync(outputPath)) {
    try {
      const parsed = JSON.parse(fs.readFileSync(outputPath, "utf8"));
      if (Array.isArray(parsed)) existing = parsed;
    } catch (_error) {
      existing = [];
    }
  }
  existing.push({ test: testInfo.title, ...measurements });
  fs.writeFileSync(outputPath, JSON.stringify(existing, null, 2) + "\n");

  await testInfo.attach("layout-measurements-" + pageName + ".json", {
    body: Buffer.from(JSON.stringify(measurements, null, 2)),
    contentType: "application/json",
  });

  expect(
    measurements.document.horizontalOverflow,
    "Document-level horizontal overflow at " + pageName +
      " (" + measurements.viewport.width + "px viewport); inspect the attached layout measurements."
  ).toBeLessThanOrEqual(2);

  return measurements;
}

module.exports = { auditLayout };