import { useEffect, useMemo, useState } from "react";
import { customersApi, type Customer } from "../api/customers";
import { errorMessage } from "../api/client";
import {
  toVehiclePayload,
  vehicleErrorMessage,
  vehiclesApi,
  type Vehicle,
  type VehicleFormValue,
} from "../api/vehicles";
import { Button, Card, Icons, Modal, Pagination, SearchBox, TableContainer } from "../components/ui";
import VehicleForm from "../features/vehicles/VehicleForm";

const PER_PAGE = 10;

const customerCode = (customerId: number) => `KH${String(customerId).padStart(3, "0")}`;

export default function Vehicles() {
  const [vehicles, setVehicles] = useState<Vehicle[]>([]);
  const [totalElements, setTotalElements] = useState(0);
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [search, setSearch] = useState("");
  const [query, setQuery] = useState("");
  const [page, setPage] = useState(1);
  const [refreshKey, setRefreshKey] = useState(0);
  const [selected, setSelected] = useState<Vehicle | null>(null);
  const [editing, setEditing] = useState<Vehicle | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [customerError, setCustomerError] = useState("");
  const [success, setSuccess] = useState("");

  // Tìm kiếm theo biển số gửi lên backend sau 300ms ngừng gõ.
  useEffect(() => {
    const timer = window.setTimeout(() => {
      setQuery(search.trim());
      setPage(1);
    }, 300);
    return () => window.clearTimeout(timer);
  }, [search]);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError("");
    vehiclesApi
      .list({ page: page - 1, size: PER_PAGE, search: query || undefined })
      .then((result) => {
        if (cancelled) return;
        setVehicles(result.items);
        setTotalElements(result.totalElements);
      })
      .catch((loadError) => {
        if (!cancelled) setError(vehicleErrorMessage(loadError, "Không thể tải danh sách xe."));
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [page, query, refreshKey]);

  useEffect(() => {
    let cancelled = false;
    customersApi
      .list()
      .then((result) => {
        if (!cancelled) setCustomers(result);
      })
      .catch((loadError) => {
        if (!cancelled) setCustomerError(errorMessage(loadError, "Không thể tải danh sách khách hàng."));
      });
    return () => {
      cancelled = true;
    };
  }, []);

  const customerName = (customerId: number) =>
    customers.find((customer) => customer.id === customerId)?.fullName ?? customerCode(customerId);

  const customerOptions = useMemo(
    () =>
      customers
        .filter((customer) => customer.active || customer.id === editing?.customerId)
        .map((customer) => ({ value: customer.id, label: `${customer.fullName} – ${customer.phone}` })),
    [customers, editing],
  );

  const openCreate = () => {
    setEditing(null);
    setSuccess("");
    setShowForm(true);
  };

  const openEdit = (vehicle: Vehicle) => {
    setEditing(vehicle);
    setSuccess("");
    setShowForm(true);
  };

  const openDetail = (vehicle: Vehicle) => {
    setSelected(vehicle);
    vehiclesApi
      .getById(vehicle.id)
      .then((fresh) => setSelected((current) => (current?.id === fresh.id ? fresh : current)))
      .catch((detailError) => setError(vehicleErrorMessage(detailError, "Không thể tải thông tin xe.")));
  };

  const toggleDetail = (vehicle: Vehicle) => {
    if (selected?.id === vehicle.id) setSelected(null);
    else openDetail(vehicle);
  };

  const handleSubmit = async (value: VehicleFormValue) => {
    if (value.customerId == null) throw new Error("Vui lòng chọn chủ xe.");
    const payload = toVehiclePayload(value.customerId, value);
    try {
      const saved = editing
        ? await vehiclesApi.update(editing.id, payload)
        : await vehiclesApi.create(payload);
      setShowForm(false);
      setSuccess(editing ? "Đã cập nhật thông tin xe." : "Đã thêm xe mới.");
      setSelected(saved);
      if (!editing) {
        setSearch("");
        setQuery("");
        setPage(1);
      }
      setRefreshKey((key) => key + 1);
    } catch (saveError) {
      throw new Error(vehicleErrorMessage(saveError, "Không thể lưu thông tin xe."));
    }
  };

  return (
    <div className="space-y-6">
      <div className="page-toolbar">
        <SearchBox value={search} onChange={setSearch} placeholder="Tìm theo biển số..." />
        <div className="flex flex-wrap gap-2">
          <Button variant="outline" onClick={() => setRefreshKey((key) => key + 1)} disabled={loading}>Tải lại</Button>
          <Button icon={Icons.plus} onClick={openCreate}>Thêm xe</Button>
        </div>
      </div>

      {error && <p className="rounded-md bg-danger-soft px-4 py-3 text-sm text-danger" role="alert">{error}</p>}
      {customerError && <p className="rounded-md bg-danger-soft px-4 py-3 text-sm text-danger" role="alert">{customerError}</p>}
      {success && <p className="rounded-md bg-success-soft px-4 py-3 text-sm text-success" role="status">{success}</p>}

      <div className={`grid gap-4 ${selected ? "xl:grid-cols-3" : "grid-cols-1"}`}>
        <div className={selected ? "xl:col-span-2" : ""}>
          <Card>
            <TableContainer>
              <table className="data-table w-full min-w-[760px]">
                <thead>
                  <tr>
                    <th>Mã xe</th>
                    <th>Biển số</th>
                    <th>Chủ xe</th>
                    <th>Hãng xe</th>
                    <th>Dòng xe</th>
                    <th className="text-right">Năm SX</th>
                    <th className="text-right">Số km</th>
                    <th>Thao tác</th>
                  </tr>
                </thead>
                <tbody>
                  {loading && <tr><td colSpan={8} className="py-10 text-center text-sm text-muted-foreground">Đang tải danh sách xe...</td></tr>}
                  {!loading && vehicles.length === 0 && !error && (
                    <tr><td colSpan={8} className="py-10 text-center text-sm text-muted-foreground">Không tìm thấy xe phù hợp.</td></tr>
                  )}
                  {!loading && vehicles.map((vehicle) => (
                    <tr
                      key={vehicle.id}
                      tabIndex={0}
                      aria-selected={selected?.id === vehicle.id}
                      onClick={() => toggleDetail(vehicle)}
                      onKeyDown={(event) => {
                        if (event.currentTarget !== event.target || (event.key !== "Enter" && event.key !== " ")) return;
                        event.preventDefault();
                        toggleDetail(vehicle);
                      }}
                      className={`cursor-pointer ${selected?.id === vehicle.id ? "bg-info-soft" : ""}`}
                    >
                      <td><span className="mono text-xs text-slate-400">{vehicle.id}</span></td>
                      <td><span className="mono font-bold text-primary">{vehicle.licensePlate}</span></td>
                      <td className="font-medium text-slate-800">{customerName(vehicle.customerId)}</td>
                      <td className="text-slate-600">{vehicle.brand || "—"}</td>
                      <td className="text-slate-600">{vehicle.model || "—"}</td>
                      <td className="text-right text-slate-600">{vehicle.year ?? "—"}</td>
                      <td className="mono text-right text-sm">{vehicle.mileage?.toLocaleString("vi-VN") ?? "—"}</td>
                      <td>
                        <div className="flex gap-1">
                          <button
                            type="button"
                            aria-label={`Xem xe ${vehicle.licensePlate}`}
                            onClick={(event) => { event.stopPropagation(); openDetail(vehicle); }}
                            className="flex h-11 w-11 items-center justify-center rounded text-slate-500 hover:bg-slate-100"
                          >{Icons.eye}</button>
                          <button
                            type="button"
                            aria-label={`Sửa xe ${vehicle.licensePlate}`}
                            onClick={(event) => { event.stopPropagation(); openEdit(vehicle); }}
                            className="flex h-11 w-11 items-center justify-center rounded text-slate-500 hover:bg-slate-100"
                          >{Icons.edit}</button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </TableContainer>
            <div className="flex flex-col gap-3 border-t border-border px-4 py-3 sm:flex-row sm:items-center sm:justify-between">
              <p className="text-xs text-muted-foreground">{totalElements} xe</p>
              <Pagination page={page} total={totalElements} perPage={PER_PAGE} onChange={setPage} />
            </div>
          </Card>
        </div>

        {selected && (
          <div className="detail-panel space-y-4">
            <Card className="p-4 sm:p-5">
              <div className="mb-4 flex items-start justify-between">
                <div>
                  <p className="mono text-2xl font-bold text-primary">{selected.licensePlate}</p>
                  <p className="font-medium text-slate-600">{[selected.brand, selected.model, selected.year].filter(Boolean).join(" ") || "Chưa cập nhật thông tin xe"}</p>
                  <p className="mono mt-1 text-xs text-slate-400">Mã xe: {selected.id}</p>
                </div>
                <button type="button" onClick={() => setSelected(null)} aria-label="Đóng chi tiết xe" className="flex h-11 w-11 items-center justify-center rounded text-slate-500 hover:bg-slate-100">{Icons.close}</button>
              </div>
              <div className="grid grid-cols-2 gap-3 text-sm">
                <div className="rounded-lg bg-slate-50 p-3"><p className="text-xs text-slate-400">Chủ xe</p><p className="font-semibold">{customerName(selected.customerId)}</p></div>
                <div className="rounded-lg bg-slate-50 p-3"><p className="text-xs text-slate-400">Mã khách hàng</p><p className="mono font-semibold">{customerCode(selected.customerId)}</p></div>
                <div className="rounded-lg bg-slate-50 p-3"><p className="text-xs text-slate-400">Số km</p><p className="mono font-semibold">{selected.mileage !== null ? `${selected.mileage.toLocaleString("vi-VN")} km` : "—"}</p></div>
                <div className="rounded-lg bg-slate-50 p-3"><p className="text-xs text-slate-400">Năm sản xuất</p><p className="font-semibold">{selected.year ?? "—"}</p></div>
              </div>
              <Button className="mt-4 w-full" variant="outline" icon={Icons.edit} onClick={() => openEdit(selected)}>Chỉnh sửa thông tin</Button>
            </Card>
          </div>
        )}
      </div>

      <Modal open={showForm} onClose={() => setShowForm(false)} title={editing ? "Cập nhật xe" : "Thêm xe"} width="max-w-xl">
        {showForm && (
          <VehicleForm
            key={editing?.id ?? "new"}
            customerOptions={customerOptions}
            lockCustomer={Boolean(editing)}
            initialValue={editing ? {
              customerId: editing.customerId,
              plate: editing.licensePlate,
              brand: editing.brand ?? "",
              model: editing.model ?? "",
              year: editing.year,
              mileage: editing.mileage,
            } : undefined}
            onSubmit={handleSubmit}
            onCancel={() => setShowForm(false)}
            submitLabel={editing ? "Lưu thay đổi" : "Lưu xe"}
            savingLabel="Đang lưu..."
          />
        )}
      </Modal>
    </div>
  );
}
