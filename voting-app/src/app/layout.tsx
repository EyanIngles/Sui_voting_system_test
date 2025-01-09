"use client";
import './globals.css'
import Navbar from "@/app/nav";

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <Navbar />
        <main>{children}</main> 
      </body>
    </html>
  );
}
