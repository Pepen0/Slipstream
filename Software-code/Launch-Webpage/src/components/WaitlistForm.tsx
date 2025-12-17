import { useState } from "react";
import { motion } from "framer-motion";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Loader2, CheckCircle, AlertCircle } from "lucide-react";

interface WaitlistFormProps {
  source: string;
  showFullForm?: boolean;
}

type FormState = "idle" | "loading" | "success" | "error";

export function WaitlistForm({ source, showFullForm = false }: WaitlistFormProps) {
  const [email, setEmail] = useState("");
  const [name, setName] = useState("");
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
      // Simulate API call - replace with actual Supabase integration
      await new Promise((resolve) => setTimeout(resolve, 1500));
      
      // For now, just log the submission
      console.log("Waitlist signup:", { email, name, source });
      
      setState("success");
      setEmail("");
      setName("");
    } catch {
      setState("error");
      setErrorMessage("Something went wrong. Please try again.");
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
      {showFullForm && (
        <div>
          <Input
            type="text"
            placeholder="First name (optional)"
            value={name}
            onChange={(e) => setName(e.target.value)}
            disabled={state === "loading"}
            className="bg-card border-border focus:border-primary"
          />
        </div>
      )}
      
      <div className="flex flex-col sm:flex-row gap-3">
        <Input
          type="email"
          placeholder="Enter your email"
          value={email}
          onChange={(e) => {
            setEmail(e.target.value);
            if (state === "error") setState("idle");
          }}
          disabled={state === "loading"}
          className="flex-1 bg-card border-border focus:border-primary"
          required
        />
        <Button 
          type="submit" 
          variant="hero" 
          size="lg"
          disabled={state === "loading"}
          className="whitespace-nowrap"
        >
          {state === "loading" ? (
            <>
              <Loader2 className="w-4 h-4 animate-spin" />
              Joining...
            </>
          ) : (
            "Join Waitlist"
          )}
        </Button>
      </div>

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
