export default function MarketLayout({
    children,
  }: {
    children: React.ReactNode;
  }) {
    return (
      <div>
        <main>{children}</main>
      </div>
    );
  }
  