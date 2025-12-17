import { motion } from "framer-motion";
import { CheckCircle, Circle, Clock } from "lucide-react";
import { RoadmapPhase } from "@/config/site";
import { cn } from "@/lib/utils";

interface RoadmapNodeProps {
  phase: RoadmapPhase;
  isActive: boolean;
  progress: number;
}

export function RoadmapNode({ phase, isActive, progress }: RoadmapNodeProps) {
  const getStatusIcon = () => {
    switch (phase.status) {
      case "completed":
        return <CheckCircle className="w-5 h-5 text-primary" />;
      case "in-progress":
        return <Clock className="w-5 h-5 text-primary animate-pulse" />;
      default:
        return <Circle className="w-5 h-5 text-muted-foreground" />;
    }
  };

  const getStatusLabel = () => {
    switch (phase.status) {
      case "completed":
        return "Completed";
      case "in-progress":
        return "In Progress";
      default:
        return "Planned";
    }
  };

  return (
    <motion.div
      className={cn(
        "relative p-6 md:p-8 rounded-2xl border transition-all duration-500",
        isActive
          ? "bg-card border-primary/50 shadow-[0_0_40px_hsl(0_85%_55%/0.15)]"
          : "bg-card/50 border-border/50"
      )}
      style={{
        opacity: 0.3 + progress * 0.7,
        transform: `scale(${0.9 + progress * 0.1})`,
      }}
    >
      {/* Phase Number */}
      <div className="absolute -top-4 -left-4 w-10 h-10 rounded-full bg-background border-2 border-primary flex items-center justify-center">
        <span className="font-display text-sm font-bold text-primary">
          {String(phase.id).padStart(2, "0")}
        </span>
      </div>

      {/* Status Badge */}
      <div className="flex items-center gap-2 mb-4">
        {getStatusIcon()}
        <span
          className={cn(
            "font-display text-xs uppercase tracking-wider",
            phase.status === "completed" || phase.status === "in-progress"
              ? "text-primary"
              : "text-muted-foreground"
          )}
        >
          {getStatusLabel()}
        </span>
      </div>

      {/* Content */}
      <h3 className="font-display text-xl md:text-2xl font-bold text-foreground mb-2">
        {phase.title}
      </h3>
      <p className="text-sm md:text-base text-muted-foreground leading-relaxed">
        {phase.description}
      </p>

      {/* Progress indicator for in-progress */}
      {phase.status === "in-progress" && (
        <div className="mt-4 h-1 bg-secondary rounded-full overflow-hidden">
          <motion.div
            className="h-full bg-primary"
            initial={{ width: "0%" }}
            animate={{ width: "60%" }}
            transition={{ duration: 1, delay: 0.5 }}
          />
        </div>
      )}
    </motion.div>
  );
}
