import { MarketingNav } from "@/components/nav"

const BACKGROUND_STYLE = {
  backgroundImage:
    "url('https://images.unsplash.com/photo-1620121684840-edffcfc4b878?q=80&w=2232&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D')",
  backgroundSize: "cover",
  backgroundPosition: "center",
  backgroundRepeat: "no-repeat",
} as const

export default function MarketingLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <div className="relative min-h-screen overflow-x-hidden">
      {/* Fixed background */}
      <div className="fixed inset-0 -z-10" style={BACKGROUND_STYLE} />

      {/* Scrollable content */}
      <section>
        <div className="px-2 pt-10 sm:pt-16 md:px-0">
          <div
            className="relative z-10 mx-auto flex min-h-screen max-w-4xl flex-col backdrop-blur-md"
            style={{
              background: "rgba(45, 45, 45, 0.75)",
              borderRadius: "20px",
              border: "1px solid rgba(255, 255, 255, 0.15)",
              boxShadow: `
                0 8px 32px rgba(0, 0, 0, 0.4),
                0 4px 16px rgba(0, 0, 0, 0.3),
                inset 0 1px 0 rgba(255, 255, 255, 0.15),
                inset 0 -1px 0 rgba(0, 0, 0, 0.2)
              `,
            }}
          >
            <MarketingNav />
            <main className="flex flex-1 flex-col">{children}</main>

            {/* Minimal Footer */}
          </div>
          <footer className="mt-auto flex w-full items-center justify-center gap-2 py-8 text-xs  text-white">
            {/* <img
              src="/images/logo.png"
              alt="qoma logo"
              className="h-4 w-4 opacity-60 grayscale"
            /> */}
            <span>
              <span className="font-bold">qoma.live</span> &copy; 2026 qoma
            </span>
          </footer>
        </div>
      </section>
    </div>
  )
}
