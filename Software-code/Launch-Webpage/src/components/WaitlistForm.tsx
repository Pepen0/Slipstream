import { useState } from "react";
import { motion } from "framer-motion";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Loader2, CheckCircle, AlertCircle } from "lucide-react";

interface WaitlistFormProps {
  source?: string;
}

type FormState = "idle" | "loading" | "success" | "error";

// Get endpoint from environment variable
const waitlistEndpoint = import.meta.env.VITE_WAITLIST_ENDPOINT || "";

export function WaitlistForm({ source }: WaitlistFormProps) {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [recommendation, setRecommendation] = useState("");
  const [state, setState] = useState<FormState>("idle");
  const [errorMessage, setErrorMessage] = useState("");

  const validateEmail = (email: string) => {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!validateEmail(email)) {
      setState("error");
      setErrorMessage("Please enter a valid email address.");
      return;
    }

    setState("loading");
    setErrorMessage("");

    try {
      if (!waitlistEndpoint) {
        throw new Error("Waitlist endpoint not configured");
      }

      // Use URLSearchParams for Apps Script compatibility (avoids CORS preflight)
      const formData = new URLSearchParams();
      formData.append("name", name);
      formData.append("email", email);
      formData.append("recommendation", recommendation);
      formData.append("source", source || "");

      const res = await fetch(waitlistEndpoint, {
        method: "POST",
        body: formData,
      });

      const data = await res.json();
      if (!data.success) {
        throw new Error(data.error || "Failed to join waitlist");
      }

      setState("success");
      setName("");
      setEmail("");
      setRecommendation("");
    } catch (err) {
      setState("error");
      setErrorMessage(err instanceof Error ? err.message : "Something went wrong. Please try again.");
    }
  };

  if (state === "success") {
    return (
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        className="flex flex-col items-center gap-4 p-6 rounded-lg bg-card border border-border"
      >
        <CheckCircle className="w-12 h-12 text-primary" />
        <div className="text-center">
          <h3 className="font-display text-lg font-semibold text-foreground">
            You're on the list!
          </h3>
          <p className="mt-2 text-sm text-muted-foreground">
            We'll notify you when Slipstream launches.
          </p>
        </div>
      </motion.div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="w-full space-y-4">
      {/* Name (optional) */}
      <div>
        <label className="block text-sm font-medium text-muted-foreground mb-1.5">
          Name (optional)
        </label>
        <Input
          type="text"
          placeholder="Your name"
          value={name}
          onChange={(e) => setName(e.target.value)}
          disabled={state === "loading"}
          className="bg-card border-border focus:border-primary"
        />
      </div>

      {/* Email (required) */}
      <div>
        <label className="block text-sm font-medium text-muted-foreground mb-1.5">
          Email (required)
        </label>
        <Input
          type="email"
          placeholder="your@email.com"
          value={email}
          onChange={(e) => {
            setEmail(e.target.value);
            if (state === "error") setState("idle");
          }}
          disabled={state === "loading"}
          className="bg-card border-border focus:border-primary"
          required
        />
      </div>

      {/* Recommendation (optional) */}
      <div>
        <label className="block text-sm font-medium text-muted-foreground mb-1.5">
          Recommendation (optional)
        </label>
        <textarea
          placeholder="Any feedback or suggestions?"
          value={recommendation}
          onChange={(e) => setRecommendation(e.target.value)}
          disabled={state === "loading"}
          rows={3}
          className="w-full px-3 py-2 rounded-md bg-card border border-border focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary text-foreground placeholder:text-muted-foreground resize-none"
        />
      </div>

      {/* Submit Button */}
      <Button
        type="submit"
        variant="hero"
        size="lg"
        disabled={state === "loading"}
        className="w-full"
      >
        {state === "loading" ? (
          <>
            <Loader2 className="w-4 h-4 animate-spin mr-2" />
            Joining...
          </>
        ) : (
          "Join Waitlist"
        )}
      </Button>

      {state === "error" && errorMessage && (
        <motion.div
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          className="flex items-center gap-2 text-sm text-destructive"
        >
          <AlertCircle className="w-4 h-4" />
          {errorMessage}
        </motion.div>
      )}
    </form>
  );
}

