import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "TicketGate — Live the Moment",
  description: "Discover and book concerts, movies, sports and experiences across India.",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body>{children}</body></html>;
}