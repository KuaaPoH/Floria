/** @type {import('next').NextConfig} */
const nextConfig = {
  devIndicators: false,
  images: {
    unoptimized: true,
  },
  async rewrites() {
    return [
      {
        source: "/__/auth/:path*",
        destination: "https://floria-71734.firebaseapp.com/__/auth/:path*",
      },
      {
        source: "/__/firebase/init.json",
        destination: "https://floria-71734.firebaseapp.com/__/firebase/init.json",
      },
    ];
  },
};

export default nextConfig;
