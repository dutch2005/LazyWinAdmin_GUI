import { describe, it, expect } from "vitest";
import { cn } from "./utils";

describe("cn", () => {
  it("merges basic classes", () => {
    expect(cn("class1", "class2")).toBe("class1 class2");
  });

  it("handles conditional classes", () => {
    expect(cn("class1", { class2: true, class3: false })).toBe("class1 class2");
  });

  it("resolves tailwind conflicts", () => {
    expect(cn("p-4", "p-8")).toBe("p-8");
    expect(cn("px-2 py-4", "p-8")).toBe("p-8");
    expect(cn("text-red-500", "text-blue-500")).toBe("text-blue-500");
  });

  it("ignores falsy values", () => {
    expect(cn("class1", null, undefined, false, 0, "")).toBe("class1");
  });

  it("handles array inputs", () => {
    expect(cn(["class1", "class2"])).toBe("class1 class2");
  });

  it("handles mixed inputs", () => {
    expect(
      cn(
        "class1",
        ["class2", { class3: true, class4: false }],
        "p-4",
        "p-8",
        undefined
      )
    ).toBe("class1 class2 class3 p-8");
  });
});
