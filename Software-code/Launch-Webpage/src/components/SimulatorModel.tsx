import { Suspense, useRef } from "react";
import { Canvas, useFrame } from "@react-three/fiber";
import { Float, Environment, PerspectiveCamera } from "@react-three/drei";
import * as THREE from "three";

function Simulator() {
  const groupRef = useRef<THREE.Group>(null);

  useFrame((state) => {
    if (groupRef.current) {
      // Subtle floating animation
      groupRef.current.rotation.y = Math.sin(state.clock.elapsedTime * 0.3) * 0.1;
      groupRef.current.rotation.x = Math.sin(state.clock.elapsedTime * 0.2) * 0.05;
    }
  });

  return (
    <group ref={groupRef}>
      {/* Base Platform */}
      <mesh position={[0, -0.5, 0]}>
        <boxGeometry args={[3, 0.15, 2]} />
        <meshStandardMaterial color="#2a2a2a" metalness={0.7} roughness={0.3} />
      </mesh>

      {/* Left Actuator */}
      <group position={[-1, 0, 0]}>
        <mesh position={[0, -0.2, 0]}>
          <cylinderGeometry args={[0.12, 0.15, 0.5, 16]} />
          <meshStandardMaterial color="#e53935" metalness={0.8} roughness={0.2} emissive="#e53935" emissiveIntensity={0.2} />
        </mesh>
        <mesh position={[0, 0.15, 0]}>
          <cylinderGeometry args={[0.08, 0.12, 0.4, 16]} />
          <meshStandardMaterial color="#444444" metalness={0.6} roughness={0.4} />
        </mesh>
      </group>

      {/* Right Actuator */}
      <group position={[1, 0, 0]}>
        <mesh position={[0, -0.2, 0]}>
          <cylinderGeometry args={[0.12, 0.15, 0.5, 16]} />
          <meshStandardMaterial color="#e53935" metalness={0.8} roughness={0.2} emissive="#e53935" emissiveIntensity={0.2} />
        </mesh>
        <mesh position={[0, 0.15, 0]}>
          <cylinderGeometry args={[0.08, 0.12, 0.4, 16]} />
          <meshStandardMaterial color="#444444" metalness={0.6} roughness={0.4} />
        </mesh>
      </group>

      {/* Seat Platform */}
      <mesh position={[0, 0.5, 0]} rotation={[0.05, 0, 0.02]}>
        <boxGeometry args={[2.5, 0.12, 1.5]} />
        <meshStandardMaterial color="#1f1f1f" metalness={0.5} roughness={0.5} />
      </mesh>

      {/* Seat Back Frame */}
      <mesh position={[0, 1.1, -0.5]} rotation={[-0.2, 0, 0]}>
        <boxGeometry args={[0.8, 1, 0.1]} />
        <meshStandardMaterial color="#2a2a2a" metalness={0.4} roughness={0.6} />
      </mesh>

      {/* Steering Column */}
      <mesh position={[0, 0.8, 0.4]} rotation={[0.5, 0, 0]}>
        <cylinderGeometry args={[0.04, 0.04, 0.6, 12]} />
        <meshStandardMaterial color="#3a3a3a" metalness={0.7} roughness={0.3} />
      </mesh>

      {/* Steering Wheel */}
      <mesh position={[0, 1.05, 0.6]} rotation={[0.5, 0, 0]}>
        <torusGeometry args={[0.18, 0.025, 12, 32]} />
        <meshStandardMaterial color="#333333" metalness={0.3} roughness={0.7} />
      </mesh>

      {/* Pedal Base */}
      <mesh position={[0, 0.35, 0.8]}>
        <boxGeometry args={[0.6, 0.08, 0.3]} />
        <meshStandardMaterial color="#2a2a2a" metalness={0.5} roughness={0.5} />
      </mesh>

      {/* Red accent strip */}
      <mesh position={[0, 0.57, 0.76]}>
        <boxGeometry args={[2.5, 0.02, 0.02]} />
        <meshStandardMaterial color="#e53935" emissive="#e53935" emissiveIntensity={0.8} />
      </mesh>

      {/* Additional accent lights */}
      <mesh position={[-1.25, 0.5, 0.75]}>
        <boxGeometry args={[0.02, 0.02, 0.5]} />
        <meshStandardMaterial color="#e53935" emissive="#e53935" emissiveIntensity={0.6} />
      </mesh>
      <mesh position={[1.25, 0.5, 0.75]}>
        <boxGeometry args={[0.02, 0.02, 0.5]} />
        <meshStandardMaterial color="#e53935" emissive="#e53935" emissiveIntensity={0.6} />
      </mesh>
    </group>
  );
}

function LoadingFallback() {
  return (
    <div className="w-full h-full flex items-center justify-center">
      <div className="w-16 h-16 border-2 border-primary/20 border-t-primary rounded-full animate-spin" />
    </div>
  );
}

export function SimulatorModel() {
  return (
    <div className="w-full h-[350px] md:h-[450px] lg:h-[500px]">
      <Suspense fallback={<LoadingFallback />}>
        <Canvas>
          <PerspectiveCamera makeDefault position={[4, 2.5, 5]} fov={40} />
          <ambientLight intensity={0.5} />
          <spotLight
            position={[5, 8, 5]}
            angle={0.4}
            penumbra={0.5}
            intensity={1.5}
            castShadow
            color="#ffffff"
          />
          <spotLight
            position={[-4, 4, 2]}
            angle={0.6}
            penumbra={0.8}
            intensity={0.8}
            color="#e53935"
          />
          <spotLight
            position={[0, 3, 5]}
            angle={0.5}
            penumbra={0.6}
            intensity={0.6}
            color="#ffffff"
          />
          <pointLight position={[0, 6, 0]} intensity={0.5} color="#ffffff" />
          <Float
            speed={1.5}
            rotationIntensity={0.15}
            floatIntensity={0.2}
          >
            <Simulator />
          </Float>
          <Environment preset="city" />
        </Canvas>
      </Suspense>
    </div>
  );
}
