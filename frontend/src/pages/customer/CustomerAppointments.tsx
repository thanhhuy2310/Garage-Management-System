import AppointmentWorkspace from "../../features/appointments/AppointmentWorkspace";
export default function CustomerAppointments({customerId,onBooked}: {customerKey: string; customerId: number; onBooked?: () => void}) {
  return <AppointmentWorkspace customerId={customerId} onBooked={onBooked}/>;
}
