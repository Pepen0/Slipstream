import { motion } from "framer-motion";
import { CheckCircle, Circle, Clock, Camera } from "lucide-react";
import { RoadmapPhase } from "@/config/roadmap";
import { cn } from "@/lib/utils";

interface RoadmapNodeProps {
  phase: RoadmapPhase;
  isActive: boolean;
  progress: number; // 0-1 (visual animation progress)
}

export function RoadmapNode({ phase, isActive, progress }: RoadmapNodeProps) {
  const getStatus = (progress: number) => {
    if (progress === 100) return "completed";
    if (progress > 0) return "in-progress";
    return "planned";
  };

  const status = getStatus(phase.progress);

  const getStatusIcon = () => {
    switch (status) {
      case "completed":
        return <CheckCircle className="w-4 h-4 text-primary" />;
      case "in-progress":
        return <Clock className="w-4 h-4 text-primary animate-pulse" />;
      default:
        return <Circle className="w-4 h-4 text-muted-foreground" />;
    }
  };

  const getStatusLabel = () => {
    switch (status) {
      case "completed":
        return "Completed";
      case "in-progress":
        return "In Progress";
      default:
        return "Not Started";
    }
  };

  return (
    <div
      className={cn(
        "relative w-full max-w-md mx-auto p-6 bg-card border rounded-xl overflow-hidden transition-all duration-500",
        isActive ? "border-primary/50 shadow-2xl scale-100 opacity-100" : "border-border/50 scale-95 opacity-50 blur-[1px]"
      )}
    >
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-2">
          {getStatusIcon()}
          <span
            className={cn(
              "font-display text-xs uppercase tracking-wider",
              status === "completed" || status === "in-progress"
                ? "text-primary"
                : "text-muted-foreground"
            )}
          >
            {getStatusLabel()}
          </span>
        </div>
        <span className="font-mono text-xs text-muted-foreground">
          {phase.progress}%
        </span>
      </div>

      {/* Title */}
      <h3 className="font-display text-xl font-bold text-foreground mb-2">
        {phase.title}
      </h3>
      <p className="text-sm text-muted-foreground mb-6">
        {phase.description}
      </p>

      {/* Photo Placeholder */}
      <div className="aspect-[4/3] w-full bg-secondary/30 rounded-lg flex flex-col items-center justify-center border-2 border-dashed border-border/50">
        <Camera className="w-8 h-8 text-muted-foreground/50 mb-2" />
        <span className="text-xs text-muted-foreground/50 font-display uppercase tracking-wider">
          Photo coming soon
        </span>
      </div>

      {/* Progress Bar */}
      <div className="mt-6 h-1 w-full bg-secondary rounded-full overflow-hidden">
        <motion.div
          className="h-full bg-primary"
          initial={{ width: 0 }}
          animate={{ width: `${phase.progress}%` }}
          transition={{ duration: 1, delay: 0.5 }}
        />
      </div>
    </div>
  );
}
