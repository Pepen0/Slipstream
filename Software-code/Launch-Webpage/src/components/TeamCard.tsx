import { motion } from "framer-motion";
import { User } from "lucide-react";
import { TeamMember } from "@/config/site";

interface TeamCardProps {
  member: TeamMember;
  index: number;
}

export function TeamCard({ member, index }: TeamCardProps) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 30 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: "-50px" }}
      transition={{ duration: 0.5, delay: index * 0.1 }}
      className="group"
    >
      <div className="card-glass rounded-xl p-6 hover:border-primary/30 transition-all duration-300">
        {/* Avatar */}
        <div className="w-20 h-20 mx-auto mb-4 rounded-full bg-secondary flex items-center justify-center overflow-hidden border-2 border-border group-hover:border-primary/50 transition-colors">
          <User className="w-10 h-10 text-muted-foreground" />
        </div>

        {/* Info */}
        <div className="text-center">
          <h3 className="font-display text-lg font-semibold text-foreground">
            {member.name}
          </h3>
          <p className="mt-1 font-display text-sm uppercase tracking-wider text-primary">
            {member.role}
          </p>
          <p className="mt-3 text-sm text-muted-foreground leading-relaxed">
            {member.bio}
          </p>
        </div>
      </div>
    </motion.div>
  );
}
