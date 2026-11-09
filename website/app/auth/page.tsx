import AuthPanel from "./panel"

export const dynamic = "force-dynamic"

export default async function AuthPage({ searchParams }: { searchParams: Promise<{ request?: string }> }) {
  const { request } = await searchParams
  const validRequest = typeof request === "string" && /^[a-f0-9-]{36}$/i.test(request)
  return <AuthPanel requestId={validRequest ? request : null} invalidRequest={typeof request === "string" && !validRequest} />
}
