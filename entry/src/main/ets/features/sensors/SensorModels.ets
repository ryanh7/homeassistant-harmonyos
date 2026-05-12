export interface SensorEntry {
  id: string;
  title: string;
  summary: string;
  icon: string;
  enabled: boolean;
}

export interface SensorGroup {
  title: string;
  sensors: SensorEntry[];
}

export enum SensorUpdateFrequency {
  NORMAL = 'normal',
  FAST_WHILE_CHARGING = 'fast_charging',
  FAST_ALWAYS = 'fast_always'
}
