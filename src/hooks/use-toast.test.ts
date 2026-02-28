import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { reducer } from "./use-toast";

describe("use-toast reducer", () => {
  const mockToast1 = { id: "1", title: "Toast 1", open: true };
  const mockToast2 = { id: "2", title: "Toast 2", open: true };

  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.restoreAllMocks();
    vi.useRealTimers();
  });

  describe("ADD_TOAST", () => {
    it("should add a new toast to the state", () => {
      const initialState = { toasts: [] };
      const action = { type: "ADD_TOAST" as const, toast: mockToast1 };

      const newState = reducer(initialState, action);

      expect(newState.toasts).toHaveLength(1);
      expect(newState.toasts[0]).toEqual(mockToast1);
    });

    it("should limit the number of toasts to TOAST_LIMIT (1)", () => {
      const initialState = { toasts: [mockToast1] };
      const action = { type: "ADD_TOAST" as const, toast: mockToast2 };

      const newState = reducer(initialState, action);

      // Since TOAST_LIMIT is 1 in the source file, it should only keep the newest toast
      expect(newState.toasts).toHaveLength(1);
      expect(newState.toasts[0]).toEqual(mockToast2);
    });
  });

  describe("UPDATE_TOAST", () => {
    it("should update an existing toast", () => {
      const initialState = { toasts: [mockToast1] };
      const action = {
        type: "UPDATE_TOAST" as const,
        toast: { id: "1", title: "Updated Toast 1" }
      };

      const newState = reducer(initialState, action);

      expect(newState.toasts).toHaveLength(1);
      expect(newState.toasts[0]).toEqual({ ...mockToast1, title: "Updated Toast 1" });
    });

    it("should not modify other toasts when updating", () => {
      const initialState = { toasts: [mockToast1, mockToast2] };
      const action = {
        type: "UPDATE_TOAST" as const,
        toast: { id: "1", title: "Updated Toast 1" }
      };

      const newState = reducer(initialState, action);

      expect(newState.toasts).toHaveLength(2);
      expect(newState.toasts[0]).toEqual({ ...mockToast1, title: "Updated Toast 1" });
      expect(newState.toasts[1]).toEqual(mockToast2);
    });
  });

  describe("DISMISS_TOAST", () => {
    it("should dismiss a specific toast by id", () => {
      const initialState = { toasts: [mockToast1, mockToast2] };
      const action = { type: "DISMISS_TOAST" as const, toastId: "1" };

      const newState = reducer(initialState, action);

      expect(newState.toasts).toHaveLength(2);
      expect(newState.toasts[0].open).toBe(false);
      expect(newState.toasts[1].open).toBe(true);
    });

    it("should dismiss all toasts if no id is provided", () => {
      const initialState = { toasts: [mockToast1, mockToast2] };
      const action = { type: "DISMISS_TOAST" as const };

      const newState = reducer(initialState, action);

      expect(newState.toasts).toHaveLength(2);
      expect(newState.toasts[0].open).toBe(false);
      expect(newState.toasts[1].open).toBe(false);
    });
  });

  describe("REMOVE_TOAST", () => {
    it("should remove a specific toast by id", () => {
      const initialState = { toasts: [mockToast1, mockToast2] };
      const action = { type: "REMOVE_TOAST" as const, toastId: "1" };

      const newState = reducer(initialState, action);

      expect(newState.toasts).toHaveLength(1);
      expect(newState.toasts[0]).toEqual(mockToast2);
    });

    it("should remove all toasts if no id is provided", () => {
      const initialState = { toasts: [mockToast1, mockToast2] };
      const action = { type: "REMOVE_TOAST" as const };

      const newState = reducer(initialState, action);

      expect(newState.toasts).toHaveLength(0);
    });
  });
});
