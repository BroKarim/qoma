import { Download } from "lucide-react"

const reasons = [
  {
    title: "Set your own pace",
    description:
      "Choose a focus session that fits the work in front of you. Qyube keeps the timer simple and leaves the routine up to you.",
  },
  {
    title: "A nudge, not a lock",
    description:
      "Focus modes can respond when you switch apps with a quiet visual reminder. Your Mac stays yours; Qyube never blocks your way back in.",
  },
  {
    title: "A companion while you work",
    description:
      "A little penguin fishes on the ice while you focus, giving your timer a calm place to live instead of another dashboard to manage.",
  },
]

const questions = [
  {
    question: "What is qyube?",
    answer:
      "qyube is a focus companion for Mac. Set a timer, choose how you want to focus, and let a fishing penguin keep you company while you work.",
  },
  {
    question: "Is qyube a traditional Pomodoro timer?",
    answer:
      "It gives you a focused countdown without requiring a fixed Pomodoro cycle. Choose the session length that works for you; qyube won't make you take automatic breaks.",
  },
  {
    question: "Does qyube block distracting apps or websites?",
    answer:
      "No. Focus modes can show a gentle visual reminder when you switch to an app outside your plan, but they don't lock apps or block websites.",
  },
  {
    question: "What do I need to use qyube?",
    answer:
      "qyube is a Mac app. Download it and start a focus session whenever you're ready.",
  },
]

export default function MarketingInformation() {
  return (
    <>
      <section
        id="what-is-qyube"
        className="scroll-mt-12 bg-white px-6 py-24 sm:px-10 sm:py-32 lg:px-16"
      >
        <div className="mx-auto grid max-w-5xl gap-8 md:grid-cols-[0.8fr_1.2fr] md:gap-16">
          <div>
            <p className="mb-5 text-[11px] font-medium tracking-[0.18em] text-[#777] uppercase">
              A little focus companion
            </p>
            <h2 className="max-w-sm text-4xl leading-[1.08] tracking-[-0.055em] sm:text-5xl">
              What is qyube?
            </h2>
          </div>
          <div className="max-w-xl md:pt-8">
            <p className="text-xl leading-relaxed tracking-[-0.025em] text-[#383838] sm:text-[22px]">
              qyube is a quiet focus timer for Mac, with a penguin fishing
              beside you.
            </p>
            <p className="mt-5 text-[15px] leading-7 text-[#696969]">
              Set a timer for the work in front of you and settle into it. The
              penguin keeps watch on a small stretch of Antarctic water while
              qyube helps you stay with one thing at a time.
            </p>
          </div>
        </div>
      </section>

      <section className="bg-[#f5f7f8] px-6 py-24 sm:px-10 sm:py-28 lg:px-16">
        <div className="mx-auto max-w-5xl">
          <div className="mb-14 max-w-2xl">
            <p className="mb-5 text-[11px] font-medium tracking-[0.18em] text-[#777] uppercase">
              Why qyube
            </p>
            <h2 className="text-4xl leading-[1.08] tracking-[-0.055em] sm:text-5xl">
              Focus, with room to breathe.
            </h2>
          </div>
          <div className="grid gap-9 border-t border-[#dfe3e5] pt-8 md:grid-cols-3 md:gap-8">
            {reasons.map((reason) => (
              <article key={reason.title}>
                <h3 className="text-[17px] font-medium tracking-[-0.025em]">
                  {reason.title}
                </h3>
                <p className="mt-3 text-[14px] leading-6 text-[#686868]">
                  {reason.description}
                </p>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section
        id="faq"
        className="scroll-mt-12 bg-white px-6 py-24 sm:px-10 sm:py-32 lg:px-16"
      >
        <div className="mx-auto grid max-w-5xl gap-10 md:grid-cols-[0.8fr_1.2fr] md:gap-16">
          <div>
            <p className="mb-5 text-[11px] font-medium tracking-[0.18em] text-[#777] uppercase">
              Good to know
            </p>
            <h2 className="text-4xl leading-[1.08] tracking-[-0.055em] sm:text-5xl">
              A few questions.
            </h2>
          </div>
          <div className="divide-y divide-[#e5e5e5] border-y border-[#e5e5e5]">
            {questions.map((item) => (
              <details key={item.question} className="group py-5">
                <summary className="flex cursor-pointer list-none items-center justify-between gap-6 text-[15px] font-medium tracking-[-0.015em] marker:hidden focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-[#202020] [&::-webkit-details-marker]:hidden">
                  {item.question}
                  <span
                    aria-hidden="true"
                    className="text-xl font-light text-[#777] transition-transform group-open:rotate-45"
                  >
                    +
                  </span>
                </summary>
                <p className="max-w-xl pt-3 pr-8 text-[14px] leading-6 text-[#686868]">
                  {item.answer}
                </p>
              </details>
            ))}
          </div>
        </div>
      </section>

      <footer className="border-t border-[#ececec] bg-white px-6 py-8 sm:px-10 lg:px-16">
        <div className="mx-auto flex max-w-5xl flex-col gap-5 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <a
              href="#top"
              className="text-[22px] font-semibold tracking-[-0.07em]"
              aria-label="qyube, back to top"
            >
              qyube
            </a>
            <p className="mt-1 text-[12px] text-[#858585]">
              A little focus, one session at a time.
            </p>
          </div>
          <div className="flex items-center gap-5">
            <span className="text-[12px] text-[#858585]">© 2026 qyube</span>
            <a
              href="https://github.com/BroKarim/qoma/releases/latest"
              className="inline-flex h-10 items-center gap-2 rounded-full bg-[#202020] px-4 text-[12px] font-medium text-white transition-colors hover:bg-[#3a3a3a] focus-visible:outline-2 focus-visible:outline-offset-3 focus-visible:outline-[#202020]"
            >
              <Download size={13} aria-hidden="true" />
              Download for Mac
            </a>
          </div>
        </div>
      </footer>
    </>
  )
}
