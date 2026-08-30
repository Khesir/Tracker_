import { describe, expect, it } from "vitest";
import { normalizeRelease } from "./releases";
import fixtures from "./__fixtures__/github-releases.json";

const [v0_1_4, v0_1_3, v0_1_2, v0_1_0] = fixtures;

describe("normalizeRelease", () => {
  it("strips the +buildNumber suffix from the tag for display, while preserving the raw tag", () => {
    const result = normalizeRelease(v0_1_4);

    expect(result.version).toBe("v0.1.4");
    expect(result.tag).toBe("v0.1.4+35");
  });

  it("leaves a tag with no +buildNumber suffix unchanged", () => {
    const result = normalizeRelease(v0_1_0);

    expect(result.version).toBe("v0.1.0");
    expect(result.tag).toBe("v0.1.0");
  });

  it("picks the .exe asset out of several unrelated platform assets", () => {
    const result = normalizeRelease(v0_1_4);

    expect(result.windowsAsset).toEqual({
      name: "tracker-0.1.4-windows-setup.exe",
      url: "https://github.com/Khesir/Tracker_/releases/download/v0.1.4%2B35/tracker-0.1.4-windows-setup.exe",
    });
  });

  it("identifies the .exe asset when it's the only asset published", () => {
    const result = normalizeRelease(v0_1_3);

    expect(result.windowsAsset).toEqual({
      name: "tracker-0.1.3-windows-setup.exe",
      url: "https://github.com/Khesir/Tracker_/releases/download/v0.1.3%2B30/tracker-0.1.3-windows-setup.exe",
    });
  });

  it("leaves windowsAsset undefined, without throwing, when no asset matches", () => {
    expect(() => normalizeRelease(v0_1_2)).not.toThrow();
    expect(normalizeRelease(v0_1_2).windowsAsset).toBeUndefined();
  });

  it("leaves windowsAsset undefined when there are no assets at all", () => {
    expect(() => normalizeRelease(v0_1_0)).not.toThrow();
    expect(normalizeRelease(v0_1_0).windowsAsset).toBeUndefined();
  });

  it("passes body, published_at, and the release URL through unchanged", () => {
    const result = normalizeRelease(v0_1_4);

    expect(result.body).toBe(v0_1_4.body);
    expect(result.publishedAt).toBe(v0_1_4.published_at);
    expect(result.url).toBe(v0_1_4.html_url);
  });
});
