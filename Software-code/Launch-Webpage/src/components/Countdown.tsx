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
  const [timeLeft, setTimeLeft] = useState<TimeLeft | null>(null);
  const [isLive, setIsLive] = useState(false);

  useEffect(() => {
    const calculateTimeLeft = () => {
      const now = new Date().getTime();
      const difference = launchDate - now;

      if (difference <= 0) {
        setIsLive(true);
        return null;
      }

      return {
        days: Math.floor(difference / (1000 * 60 * 60 * 24)),
        hours: Math.floor((difference % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60)),
        minutes: Math.floor((difference % (1000 * 60 * 60)) / (1000 * 60)),
        seconds: Math.floor((difference % (1000 * 60)) / 1000),
      };
    };

    // Initial calculation
    const initial = calculateTimeLeft();
    setTimeLeft(initial);
    if (!initial) setIsLive(true);

    // Update every second
    const timer = setInterval(() => {
      const result = calculateTimeLeft();
      setTimeLeft(result);
      if (!result) {
        setIsLive(true);
        clearInterval(timer);
      }
    }, 1000);

    return () => clearInterval(timer);
  }, [launchDate]);

  if (isLive) {
    return (
      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        className="flex items-center justify-center"
      >
        <div className="px-6 py-3 rounded-lg bg-primary/10 border border-primary/30">
          <span className="font-display text-lg md:text-xl uppercase tracking-wider text-primary">
            {siteConfig.launch.liveMessage}
          </span>
        </div>
      </motion.div>
    );
  }

  if (!timeLeft) return null;

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
              <span className="font-display text-2xl md:text-4xl font-bold text-foreground">
                {String(unit.value).padStart(2, "0")}
              </span>
            </motion.div>
            <span className="mt-2 font-display text-[10px] md:text-xs uppercase tracking-wider text-muted-foreground">
              {unit.label}
            </span>
          </div>
          {index < timeUnits.length - 1 && (
            <span className="font-display text-xl md:text-3xl text-muted-foreground mb-6">
              :
            </span>
          )}
        </div>
      ))}
    </div>
  );
}
