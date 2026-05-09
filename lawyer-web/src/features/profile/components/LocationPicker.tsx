import { useEffect, useRef, useState } from "react";
import { MapContainer, TileLayer, Marker, useMapEvents, useMap } from "react-leaflet";
import L from "leaflet";
import "leaflet/dist/leaflet.css";

// Fix leaflet default marker icon broken by Vite asset pipeline
delete (L.Icon.Default.prototype as unknown as Record<string, unknown>)._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png",
  iconUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png",
  shadowUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png",
});

const DEFAULT_LAT = 14.5995;
const DEFAULT_LNG = 120.9842;
const DEFAULT_ZOOM = 12;

interface NominatimResult {
  lat: string;
  lon: string;
  display_name: string;
}

interface Props {
  lat: number | null;
  lng: number | null;
  onChange: (lat: number, lng: number) => void;
}

/** Fires onChange when the map is clicked */
function ClickHandler({ onChange }: { onChange: (lat: number, lng: number) => void }) {
  useMapEvents({
    click(e) {
      onChange(e.latlng.lat, e.latlng.lng);
    },
  });
  return null;
}

/** Flies the map to the given coords whenever they change */
function FlyToLocation({ lat, lng }: { lat: number | null; lng: number | null }) {
  const map = useMap();
  useEffect(() => {
    if (lat !== null && lng !== null) {
      map.flyTo([lat, lng], 16, { duration: 1.2 });
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [lat, lng]);
  return null;
}

/** Draggable marker that syncs position back to parent */
function DraggableMarker({
  lat,
  lng,
  onChange,
}: {
  lat: number;
  lng: number;
  onChange: (lat: number, lng: number) => void;
}) {
  const markerRef = useRef<L.Marker>(null);

  return (
    <Marker
      position={[lat, lng]}
      draggable
      ref={markerRef}
      eventHandlers={{
        dragend() {
          const m = markerRef.current;
          if (m) {
            const pos = m.getLatLng();
            onChange(pos.lat, pos.lng);
          }
        },
      }}
    />
  );
}

export function LocationPicker({ lat, lng, onChange }: Props) {
  const [query, setQuery] = useState("");
  const [suggestions, setSuggestions] = useState<NominatimResult[]>([]);
  const [showSuggestions, setShowSuggestions] = useState(false);
  const [loadingSuggestions, setLoadingSuggestions] = useState(false);
  const [searchError, setSearchError] = useState("");
  const [geoLoading, setGeoLoading] = useState(false);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const wrapperRef = useRef<HTMLDivElement>(null);

  const centre: [number, number] =
    lat !== null && lng !== null ? [lat, lng] : [DEFAULT_LAT, DEFAULT_LNG];

  // Debounced autocomplete fetch
  useEffect(() => {
    const q = query.trim();
    if (q.length < 3) {
      setSuggestions([]);
      setShowSuggestions(false);
      return;
    }
    if (debounceRef.current) clearTimeout(debounceRef.current);
    debounceRef.current = setTimeout(async () => {
      setLoadingSuggestions(true);
      setSearchError("");
      try {
        const url = `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(q)}&format=json&limit=5&countrycodes=ph`;
        const res = await fetch(url, {
          headers: { "Accept-Language": "en", "User-Agent": "CLAiR-lawyer-portal/1.0" },
        });
        const results: NominatimResult[] = await res.json();
        setSuggestions(results);
        setShowSuggestions(results.length > 0);
        if (results.length === 0) setSearchError("No results found. Try a different query.");
      } catch {
        setSearchError("Could not reach the geocoding service.");
      } finally {
        setLoadingSuggestions(false);
      }
    }, 350);
  }, [query]);

  // Close dropdown when clicking outside
  useEffect(() => {
    function handleClick(e: MouseEvent) {
      if (wrapperRef.current && !wrapperRef.current.contains(e.target as Node)) {
        setShowSuggestions(false);
      }
    }
    document.addEventListener("mousedown", handleClick);
    return () => document.removeEventListener("mousedown", handleClick);
  }, []);

  function selectSuggestion(result: NominatimResult) {
    onChange(parseFloat(result.lat), parseFloat(result.lon));
    setQuery(result.display_name);
    setShowSuggestions(false);
    setSuggestions([]);
    setSearchError("");
  }

  function handleKeyDown(e: React.KeyboardEvent) {
    if (e.key === "Enter" && suggestions.length > 0) {
      e.preventDefault();
      selectSuggestion(suggestions[0]);
    }
  }

  function useMyLocation() {
    if (!navigator.geolocation) {
      setSearchError("Geolocation is not supported by your browser.");
      return;
    }
    setGeoLoading(true);
    setSearchError("");
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        onChange(pos.coords.latitude, pos.coords.longitude);
        setGeoLoading(false);
      },
      (err) => {
        setSearchError(
          err.code === 1
            ? "Location access denied. Please allow location in your browser settings."
            : "Could not get your location. Try again."
        );
        setGeoLoading(false);
      },
      { enableHighAccuracy: true, timeout: 10000 },
    );
  }

  return (
    <div className="space-y-3">
      {/* Address search with autocomplete */}
      <div ref={wrapperRef} className="relative">
        <div className="flex gap-2">
          <button
            type="button"
            onClick={useMyLocation}
            disabled={geoLoading}
            title="Use my current location"
            className="shrink-0 flex items-center gap-1.5 px-3 py-2 rounded-xl border border-[#d9b8c4] bg-[#fdf8fb] text-sm font-semibold text-[#703d57] hover:bg-[#f7f0f4] disabled:opacity-60 transition"
          >
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" className="w-4 h-4">
              <path fillRule="evenodd" d="M11.54 22.351l.07.04.028.016a.76.76 0 00.723 0l.028-.015.071-.041a16.975 16.975 0 001.144-.742 19.58 19.58 0 002.683-2.282c1.944-1.99 3.963-4.98 3.963-8.827a8.25 8.25 0 00-16.5 0c0 3.846 2.02 6.837 3.963 8.827a19.58 19.58 0 002.682 2.282 16.975 16.975 0 001.145.742zM12 13.5a3 3 0 100-6 3 3 0 000 6z" clipRule="evenodd" />
            </svg>
            {geoLoading ? "Locating…" : "My location"}
          </button>
          <div className="relative flex-1">
            <input
              type="text"
              value={query}
              onChange={(e) => { setQuery(e.target.value); setSearchError(""); }}
              onFocus={() => { if (suggestions.length > 0) setShowSuggestions(true); }}
              onKeyDown={handleKeyDown}
              placeholder="Search an address to place the pin…"
              className="w-full rounded-xl border border-[#d9b8c4] bg-[#fdf8fb] px-3 py-2 text-sm text-[#241715] placeholder-[#c4a0b4] focus:outline-none focus:ring-2 focus:ring-[#703d57]/30"
            />
            {loadingSuggestions && (
              <span className="absolute right-3 top-1/2 -translate-y-1/2 text-xs text-[#957186]">
                Searching…
              </span>
            )}
          </div>{/* relative flex-1 */}
        </div>{/* flex gap-2 */}

        {/* Suggestions dropdown */}
        {showSuggestions && suggestions.length > 0 && (
          <ul className="absolute z-[9999] left-0 right-0 mt-1 rounded-xl border border-[#d9b8c4] bg-white shadow-lg overflow-hidden">
            {suggestions.map((s, i) => (
              <li key={i}>
                <button
                  type="button"
                  onMouseDown={(e) => e.preventDefault()}
                  onClick={() => selectSuggestion(s)}
                  className="w-full text-left px-4 py-2.5 text-sm text-[#241715] hover:bg-[#f7f0f4] transition-colors border-b border-[#f0e6ec] last:border-0"
                >
                  <span className="line-clamp-1">{s.display_name}</span>
                </button>
              </li>
            ))}
          </ul>
        )}
      </div>

      {searchError && <p className="text-xs text-red-500">{searchError}</p>}

      <p className="text-xs text-[#957186]">
        Type an address and select a suggestion, or click anywhere on the map to pin your office.
        {lat !== null && lng !== null && (
          <span className="ml-2 font-mono text-[#703d57]">
            {lat.toFixed(5)}, {lng.toFixed(5)}
          </span>
        )}
      </p>

      <div className="rounded-xl overflow-hidden border border-[#d9b8c4]/50" style={{ height: 320 }}>
        <MapContainer
          center={centre}
          zoom={DEFAULT_ZOOM}
          style={{ height: "100%", width: "100%" }}
        >
          <TileLayer
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          />
          {/* Flies to pin whenever lat/lng changes (e.g. after selecting a suggestion) */}
          <FlyToLocation lat={lat} lng={lng} />
          <ClickHandler onChange={onChange} />
          {lat !== null && lng !== null && (
            <DraggableMarker lat={lat} lng={lng} onChange={onChange} />
          )}
        </MapContainer>
      </div>
    </div>
  );
}
