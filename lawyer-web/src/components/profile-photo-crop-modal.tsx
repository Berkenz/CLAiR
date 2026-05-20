import { useCallback, useState } from "react";
import Cropper, { type Area } from "react-easy-crop";
import { getCroppedImageBlob } from "@/lib/crop-image";
import { cn } from "@/lib/cn";
import { X, ZoomIn, ZoomOut } from "lucide-react";

type ProfilePhotoCropModalProps = {
  imageSrc: string;
  onCancel: () => void;
  onConfirm: (file: File) => void;
  confirming?: boolean;
};

export function ProfilePhotoCropModal({
  imageSrc,
  onCancel,
  onConfirm,
  confirming = false,
}: ProfilePhotoCropModalProps) {
  const [crop, setCrop] = useState({ x: 0, y: 0 });
  const [zoom, setZoom] = useState(1);
  const [croppedAreaPixels, setCroppedAreaPixels] = useState<Area | null>(null);
  const [processing, setProcessing] = useState(false);

  const onCropComplete = useCallback((_area: Area, pixels: Area) => {
    setCroppedAreaPixels(pixels);
  }, []);

  async function handleConfirm() {
    if (!croppedAreaPixels) return;
    setProcessing(true);
    try {
      const blob = await getCroppedImageBlob(imageSrc, croppedAreaPixels);
      const file = new File([blob], "profile-photo.jpg", { type: "image/jpeg" });
      onConfirm(file);
    } finally {
      setProcessing(false);
    }
  }

  const busy = confirming || processing;

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
      role="dialog"
      aria-modal="true"
      aria-labelledby="crop-photo-title"
    >
      <div className="w-full max-w-md rounded-2xl border border-[#d9b8c4]/60 bg-white shadow-xl overflow-hidden">
        <div className="flex items-center justify-between border-b border-[#d9b8c4]/40 px-5 py-4">
          <h2 id="crop-photo-title" className="text-sm font-semibold text-[#241715]">
            Crop profile photo
          </h2>
          <button
            type="button"
            onClick={onCancel}
            disabled={busy}
            className="rounded-lg p-1.5 text-[#957186] hover:bg-[#f7f0f4] transition disabled:opacity-50"
            aria-label="Close"
          >
            <X className="h-4 w-4" />
          </button>
        </div>

        <div className="relative h-72 bg-[#241715]">
          <Cropper
            image={imageSrc}
            crop={crop}
            zoom={zoom}
            aspect={1}
            cropShape="round"
            showGrid={false}
            onCropChange={setCrop}
            onZoomChange={setZoom}
            onCropComplete={onCropComplete}
          />
        </div>

        <div className="flex items-center gap-3 px-5 py-3 border-t border-[#d9b8c4]/30">
          <ZoomOut className="h-4 w-4 text-[#957186] shrink-0" />
          <input
            type="range"
            min={1}
            max={3}
            step={0.05}
            value={zoom}
            onChange={(e) => setZoom(Number(e.target.value))}
            className="flex-1 accent-[#703d57]"
            aria-label="Zoom"
          />
          <ZoomIn className="h-4 w-4 text-[#957186] shrink-0" />
        </div>

        <div className="flex gap-3 px-5 pb-5">
          <button
            type="button"
            onClick={onCancel}
            disabled={busy}
            className="flex-1 rounded-xl border border-[#d9b8c4] px-4 py-2.5 text-sm font-medium text-[#703d57] hover:bg-[#f7f0f4] transition disabled:opacity-50"
          >
            Cancel
          </button>
          <button
            type="button"
            onClick={() => void handleConfirm()}
            disabled={busy || !croppedAreaPixels}
            className={cn(
              "flex-1 rounded-xl px-4 py-2.5 text-sm font-semibold text-white transition disabled:opacity-50",
              "bg-[#703d57] hover:bg-[#5a3046]",
            )}
          >
            {busy ? "Saving…" : "Use photo"}
          </button>
        </div>
      </div>
    </div>
  );
}
