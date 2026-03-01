import { useEffect, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { supabase } from "@/lib/supabaseClient";

export default function Unsubscribe() {
  const [searchParams] = useSearchParams();
  const [status, setStatus] = useState<"loading" | "success" | "error">("loading");

  useEffect(() => {
    const token = searchParams.get("token");

    if (!token) {
      setStatus("error");
      return;
    }

    const unsubscribe = async () => {
      try {
        const { error } = await supabase.functions.invoke("unsubscribe", {
          body: { token }
        });

        if (error) {
          throw error;
        }

        setStatus("success");
      } catch (err) {
        console.error(err);
        setStatus("error");
      }
    };

    unsubscribe();
  }, [searchParams]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-background text-foreground">
      <div className="max-w-md w-full p-8 text-center space-y-6">
        {status === "loading" && (
          <div>
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto mb-4"></div>
            <h1 className="text-2xl font-bold">Unsubscribing...</h1>
            <p className="text-muted-foreground mt-2">Please wait while we process your request.</p>
          </div>
        )}

        {status === "success" && (
          <div>
            <div className="h-12 w-12 rounded-full bg-green-100 text-green-600 flex items-center justify-center mx-auto mb-4">
              <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
              </svg>
            </div>
            <h1 className="text-2xl font-bold">Successfully Unsubscribed</h1>
            <p className="text-muted-foreground mt-2">
              You have been removed from the mailing list and will no longer receive emails from us.
            </p>
          </div>
        )}

        {status === "error" && (
          <div>
            <div className="h-12 w-12 rounded-full bg-red-100 text-red-600 flex items-center justify-center mx-auto mb-4">
              <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </div>
            <h1 className="text-2xl font-bold">Oops! Something went wrong</h1>
            <p className="text-muted-foreground mt-2">
              We couldn't process your unsubscription. The link may be invalid or expired.
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
