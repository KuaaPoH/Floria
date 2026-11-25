export type DataMode = "mock" | "api";

export const env = {
  dataMode: ((process.env.NEXT_PUBLIC_DATA_MODE as string | undefined) ?? "mock") as DataMode,
  apiUrl: (process.env.NEXT_PUBLIC_USER_API_URL as string | undefined) ?? "/api/user",
  cloudinaryCloudName: "vbiltn75",
  zaloPayAppId: 2554,
  appVersion: "v0.0.1",
  openMeteoUrl: "https://api.open-meteo.com/v1/forecast",
  provincesUrl: "https://esgoo.net/api-tinhthanh-new",
};

export const isMock = () => env.dataMode === "mock";
