import type { NextConfig } from "next"

const nextConfig: NextConfig = {
  output: "standalone",
  images: {
    remotePatterns: [
      { protocol: "https", hostname: "cdn.jim-nielsen.com" },
      { protocol: "https", hostname: "framerusercontent.com" },
    ],
  },
}

export default nextConfig
