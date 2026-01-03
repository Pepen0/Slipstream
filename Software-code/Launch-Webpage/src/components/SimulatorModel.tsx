import { Suspense, useRef, useState, useEffect } from "react";
import { Canvas, useFrame } from "@react-three/fiber";
import { Environment, PerspectiveCamera, useGLTF } from "@react-three/drei";
import { useReducedMotion } from "framer-motion";
import * as THREE from "three";
import { cn } from "@/lib/utils";

// --- Types & Helpers ---
interface DeviceMemoryNavigator extends Navigator {
  deviceMemory?: number;
}

// Reuse the type for the group reference
type GroupRef = THREE.Group;

function Simulator({
  prefersReducedMotion,
  hasFinePointer,
}: {
  prefersReducedMotion: boolean;
  hasFinePointer: boolean;
}) {
  // Load the GLB model
  const { scene } = useGLTF("/models/slipstream.glb");
  const groupRef = useRef<GroupRef>(null);

  // Mouse position tracking
  const mouseRef = useRef({ x: 0, y: 0 });

  useEffect(() => {
    if (prefersReducedMotion || !hasFinePointer) return;

    const handleMouseMove = (e: MouseEvent) => {
      // Normalize mouse position to [-1, 1]
      mouseRef.current = {
        x: (e.clientX / window.innerWidth) * 2 - 1,
        y: -(e.clientY / window.innerHeight) * 2 + 1,
      };
    };

    window.addEventListener("mousemove", handleMouseMove);
    return () => window.removeEventListener("mousemove", handleMouseMove);
  }, [prefersReducedMotion, hasFinePointer]);

  useFrame((state, delta) => {
    if (!groupRef.current) return;

    // Base rotation (idle)
    if (!prefersReducedMotion) {
      if (hasFinePointer) {
        // Pointer follow logic
        const targetYaw = mouseRef.current.x * 0.25; // Max 0.25 rad yaw
        const targetPitch = mouseRef.current.y * 0.1; // Max 0.1 rad pitch

        // Smooth interpolation
        // Using damp helper or simple lerp
        // THREE.MathUtils.lerp is standard
        groupRef.current.rotation.y = THREE.MathUtils.lerp(
          groupRef.current.rotation.y,
          targetYaw + Math.sin(state.clock.elapsedTime * 0.2) * 0.05, // Add slight breathing
          delta * 2
        );
        groupRef.current.rotation.x = THREE.MathUtils.lerp(
          groupRef.current.rotation.x,
          targetPitch,
          delta * 2
        );
      } else {
        // Touch/Idle logic: Gentle spin
        groupRef.current.rotation.y = Math.sin(state.clock.elapsedTime * 0.15) * 0.1;
      }
    }
  });

  return (
    <primitive
      object={scene}
      ref={groupRef}
      scale={4}
      position={[0, -0, 0]}
      rotation={[0, -0.6, 0]} // Slight initial offset for 3/4 view
    />
  );
}

function LoadingFallback() {
  return (
    <div className="w-full h-full flex items-center justify-center">
      {/* Optional: Add a subtle loading state or keep generic */}
    </div>
  );
}

function ErrorFallback() {
  return (
    <div className="w-full h-full flex items-center justify-center bg-secondary/10">
      {/* Static image fallback could go here if the component errors out */}
      <div className="text-muted-foreground text-sm">Preview Unavailable</div>
    </div>
  )
}

export function SimulatorModel() {
  // 1. Device Capabilities Check
  const [isLowEnd, setIsLowEnd] = useState(false);
  const prefersReducedMotion = useReducedMotion() ?? false;
  // Check for fine pointer (mouse) vs touch
  const [hasFinePointer, setHasFinePointer] = useState(false);
  const [mount3D, setMount3D] = useState(false);

  useEffect(() => {
    // Check device memory
    const nav = navigator as DeviceMemoryNavigator;
    if (nav.deviceMemory && nav.deviceMemory < 4) {
      setIsLowEnd(true);
    }

    // Check pointer capability
    const mediaQuery = window.matchMedia("(pointer: fine)");
    setHasFinePointer(mediaQuery.matches);

    // Listener for pointer changes (hybrid devices)
    const handler = (e: MediaQueryListEvent) => setHasFinePointer(e.matches);
    mediaQuery.addEventListener("change", handler);

    // Delay mounting slightly to prioritize LCP
    const timer = setTimeout(() => {
      setMount3D(true);
    }, 100);

    return () => {
      mediaQuery.removeEventListener("change", handler);
      clearTimeout(timer);
    }
  }, []);

  // Performance/Low-end Fallback
  // If low end, we can return null or a static image comp directly entirely skipping the Canvas
  if (isLowEnd) {
    // In a real scenario, return a static <img> here
    return null;
  }

  if (!mount3D) return <LoadingFallback />;

  return (
    <div className={cn("w-full h-full")}>
      <Suspense fallback={<LoadingFallback />}>
        <Canvas
          dpr={[1, 2]} // Clamp pixel ratio for performance
          gl={{ antialias: true, alpha: true, powerPreference: "high-performance" }}
        >
          <PerspectiveCamera makeDefault position={[0, 0, 8]} fov={35} />
          <ambientLight intensity={0.4} />
          <spotLight
            position={[10, 10, 10]}
            angle={0.15}
            penumbra={1}
            intensity={1}
            castShadow
          />
          {/* Fill light */}
          <pointLight position={[-10, -10, -10]} intensity={0.5} color="#e53935" />

          <Simulator
            prefersReducedMotion={prefersReducedMotion}
            hasFinePointer={hasFinePointer}
          />

          <Environment preset="city" blur={1} />
        </Canvas>
      </Suspense>
    </div>
  );
}

// Preload the model
useGLTF.preload("/models/slipstream.glb");
