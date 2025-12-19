import { useState, useEffect, useMemo } from "react";
import { motion } from "framer-motion";
import { siteConfig } from "@/config/site";

interface TimeLeft {
  days: number;
  hours: number;
  minutes: number;
  seconds: number;
}

export function Countdown() {
  const launchDate = useMemo(() => new Date(siteConfig.launch.date).getTime(), []);
  const [timeLeft, setTimeLeft] = useState<TimeLeft>({ days: 0, hours: 0, minutes: 0, seconds: 0 });
  const [isExpired, setIsExpired] = useState(false);
  const [isUrgent, setIsUrgent] = useState(false);

  useEffect(() => {
    const calculateTimeLeft = () => {
      const now = new Date().getTime();
      const remainingMs = launchDate - now;

      if (remainingMs <= 0) {
        setIsExpired(true);
        setIsUrgent(false);
        return { days: 0, hours: 0, minutes: 0, seconds: 0 };
      }

      const days = Math.floor(remainingMs / (1000 * 60 * 60 * 24));
      const hours = Math.floor((remainingMs % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
      const minutes = Math.floor((remainingMs % (1000 * 60 * 60)) / (1000 * 60));
      const seconds = Math.floor((remainingMs % (1000 * 60)) / 1000);

      // Check if urgent (less than 24 hours remaining)
      setIsUrgent(days < 1);
      setIsExpired(false);

      return { days, hours, minutes, seconds };
    };

    // Initial calculation
    const initial = calculateTimeLeft();
    setTimeLeft(initial);

    // Update every second
    const timer = setInterval(() => {
      const result = calculateTimeLeft();
      setTimeLeft(result);

      // Stop interval when expired
      if (isExpired) {
        clearInterval(timer);
      }
    }, 1000);

    return () => clearInterval(timer);
  }, [launchDate, isExpired]);

  const timeUnits = [
    { label: "Days", value: timeLeft.days },
    { label: "Hours", value: timeLeft.hours },
    { label: "Minutes", value: timeLeft.minutes },
    { label: "Seconds", value: timeLeft.seconds },
  ];

  return (
    <div className="flex items-center justify-center gap-2 md:gap-4">
      {timeUnits.map((unit, index) => (
        <div key={unit.label} className="flex items-center gap-2 md:gap-4">
          <div className="flex flex-col items-center">
            <motion.div
              key={unit.value}
              initial={{ opacity: 0.8, y: -5 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.2 }}
              className="w-14 h-14 md:w-20 md:h-20 flex items-center justify-center rounded-lg bg-card border border-border"
            >
              <span
                className={`font-display text-2xl md:text-4xl font-bold ${isExpired
                    ? "countdown-expired"
                    : isUrgent
                      ? "text-red-500"
                      : "text-foreground"
                  }`}
              >
                {String(unit.value).padStart(2, "0")}
              </span>
            </motion.div>
            <span className="mt-2 font-display text-[10px] md:text-xs uppercase tracking-wider text-muted-foreground">
              {unit.label}
            </span>
          </div>
          {index < timeUnits.length - 1 && (
            <span
              className={`font-display text-xl md:text-3xl mb-6 ${isExpired
                  ? "countdown-expired"
                  : isUrgent
                    ? "text-red-500"
                    : "text-muted-foreground"
                }`}
            >
              :
            </span>
          )}
        </div>
      ))}
    </div>
  );
}

// Export isExpired state for use in other components
export function useCountdownState() {
  const launchDate = useMemo(() => new Date(siteConfig.launch.date).getTime(), []);
  const [isExpired, setIsExpired] = useState(false);

  useEffect(() => {
    const checkExpired = () => {
      const now = new Date().getTime();
      const remainingMs = launchDate - now;
      setIsExpired(remainingMs <= 0);
    };

    checkExpired();
    const timer = setInterval(checkExpired, 1000);

    return () => clearInterval(timer);
  }, [launchDate]);

  return { isExpired };
}
