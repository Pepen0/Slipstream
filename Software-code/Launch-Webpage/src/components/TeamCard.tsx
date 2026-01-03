import { motion } from "framer-motion";
import { User } from "lucide-react";
import { TeamMember } from "@/config/site";

interface TeamCardProps {
  member: TeamMember;
  index: number;
}

// LinkedIn SVG icon component
function LinkedInIcon({ className }: { className?: string }) {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 24 24"
      fill="currentColor"
      className={className}
    >
      <path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z" />
    </svg>
  );
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
        {/* Headshot */}
        <div className="w-28 h-28 mx-auto mb-4 rounded-full bg-secondary flex items-center justify-center overflow-hidden border-2 border-border group-hover:border-primary/50 transition-colors">
          {member.image ? (
            <img
              src={member.image}
              alt={`${member.name} headshot`}
              className="w-full h-full object-cover"
              loading="lazy"
            />
          ) : (
            <User className="w-12 h-12 text-muted-foreground" />
          )}
        </div>

        {/* Info */}
        <div className="text-center">
          <div className="flex items-center justify-center gap-2">
            <h3 className="font-display text-lg font-semibold text-foreground">
              {member.name}
            </h3>
            {member.linkedin && (
              <a
                href={member.linkedin}
                target="_blank"
                rel="noopener noreferrer"
                aria-label={`View ${member.name} on LinkedIn`}
                className="inline-flex items-center justify-center w-6 h-6 rounded-full border border-neutral-700 hover:bg-neutral-800 hover:border-primary/50 hover:scale-110 transition-all"
              >
                <LinkedInIcon className="w-3.5 h-3.5 text-muted-foreground group-hover:text-primary" />
              </a>
            )}
          </div>
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
