import { useEffect } from "react";
import { useSearchParams } from "react-router-dom";
import { db } from "@/lib/supabaseClient";

const CONSENT_KEY = "mm_consent";
const STORAGE_KEY = "mm_ut";

export const useVisitTracking = () => {
  const [searchParams] = useSearchParams();
  const urlToken = searchParams.get("ut");

  useEffect(() => {
    let activeToken = urlToken;

    const hasConsent = localStorage.getItem(CONSENT_KEY) === "granted";

    // If user has granted consent and we have a token in URL, save it
    if (hasConsent && urlToken) {
      localStorage.setItem(STORAGE_KEY, urlToken);
    }

    // If we don't have a token in the URL, but they gave consent previously, check local storage
    if (!activeToken && hasConsent) {
      activeToken = localStorage.getItem(STORAGE_KEY);
    }

    // If user denied consent or hasn't responded, clear token from local storage (if it exists)
    if (!hasConsent) {
      localStorage.removeItem(STORAGE_KEY);
    }

    if (activeToken) {
      // Fire and forget the tracking call to the Edge Function
      db.functions.invoke("track-visit", {
        body: { token: activeToken },
      }).catch(err => {
        console.error("Tracking error:", err);
      });
    }

  }, [urlToken]);
};
