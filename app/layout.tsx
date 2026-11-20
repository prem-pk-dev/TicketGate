import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "TicketGate — Live the Moment",
  description: "Discover and book concerts, movies, sports and experiences across India.",
  icons: { icon: "https://media-assets-4sb.pages.dev/logos/brands/ticketgate-icon.svg" },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body>{children}</body></html>;
}