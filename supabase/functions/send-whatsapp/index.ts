// Sends the "milk delivered" WhatsApp template. Secrets: WA_TOKEN, WA_PHONE_ID, WA_TEMPLATE
import { createClient } from "npm:@supabase/supabase-js@2";
Deno.serve(async (req) => {
  const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const jwt = (req.headers.get("Authorization") ?? "").replace("Bearer ", "");
  const { data: u } = await sb.auth.getUser(jwt);
  if (!u.user) return new Response("unauthorized", { status: 401 });
  const { data: prof } = await sb.from("profiles").select("role").eq("id", u.user.id).single();
  if (prof?.role !== "admin") return new Response("forbidden", { status: 403 });

  const { delivery_id } = await req.json();
  const { data: d } = await sb.from("deliveries").select("id,date,qty_litre,customers(name,phone)").eq("id", delivery_id).single();
  if (!d) return new Response("not found", { status: 404 });
  const c = d.customers as { name: string; phone: string };
  const res = await fetch(`https://graph.facebook.com/v21.0/${Deno.env.get("WA_PHONE_ID")}/messages`, {
    method: "POST",
    headers: { Authorization: `Bearer ${Deno.env.get("WA_TOKEN")}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      messaging_product: "whatsapp", to: `91${c.phone}`, type: "template",
      template: { name: Deno.env.get("WA_TEMPLATE") ?? "milk_delivered", language: { code: "en" },
        components: [{ type: "body", parameters: [
          { type: "text", text: c.name }, { type: "text", text: String(d.qty_litre) }, { type: "text", text: d.date }] }] },
    }),
  });
  await sb.from("deliveries").update({ whatsapp_status: res.ok ? "sent" : "failed" }).eq("id", delivery_id);
  return new Response(await res.text(), { status: res.ok ? 200 : 502 });
});
