import CompleteLoginPanel from "./panel"

export default async function CompleteLoginPage({ searchParams }: { searchParams: Promise<{ request?: string }> }) {
  const { request } = await searchParams
  const validRequest = typeof request === "string" && /^[a-f0-9-]{36}$/i.test(request)
  return <CompleteLoginPanel requestId={validRequest ? request : null} invalidRequest={typeof request !== "string" || !validRequest} />
}
