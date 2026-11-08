import { insuranceApi, type Claim, type Policy } from "../../api/insurance"
import { Input, Select, Textarea } from "../../components/ui"
import { InsuranceForm, val } from "./forms"

interface ClaimFormProps {
  policies: Policy[]
  receptions: { id: number; receivedAt: string }[]
  fixedReception?: number
  onCreated?: (id: number) => void
  onSaved: () => void
}

export default function ClaimForm({ policies, receptions, fixedReception, onCreated, onSaved }: ClaimFormProps) {
  async function save(form: FormData) {
    const claim = await insuranceApi.save<Claim>("claims", {
      policyId: Number(form.get("policy")),
      receptionId: fixedReception ?? Number(form.get("reception")),
      incidentAt: val(form, "incidentAt"),
      insurerClaimNumber: val(form, "number") || null,
      incidentLocation: val(form, "location"),
      causeDescription: val(form, "cause"),
      damageDescription: val(form, "damage"),
    })
    onCreated?.(claim.id)
  }
  return <InsuranceForm title={fixedReception ? "Sử dụng bảo hiểm cho lần sửa chữa này" : "Mở hồ sơ tổn thất"}
    done={onSaved} save={save}>
    <Select name="policy" label="Hợp đồng" required options={policies.map(p => ({value: String(p.id), label: p.policyNumber}))}/>
    {fixedReception == null && <Select name="reception" label="Phiếu tiếp nhận" required
      options={receptions.map(r => ({value: String(r.id), label: `TN${r.id} · ${r.receivedAt}`}))}/>}
    <Input name="number" label="Mã hồ sơ phía bảo hiểm"/>
    <Input name="incidentAt" label="Thời điểm sự cố" type="datetime-local" required/>
    <Input name="location" label="Địa điểm" required/>
    <Textarea name="cause" label="Nguyên nhân" required/>
    <Textarea name="damage" label="Tổn thất ghi nhận" required/>
  </InsuranceForm>
}
