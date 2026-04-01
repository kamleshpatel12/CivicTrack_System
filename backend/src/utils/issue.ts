import { ILocation } from "./location";

export interface IIssue {
  id?: number;
  citizenId: number;
  issueType:
    | "Road Infrastructure"
    | "Waste Management"
    | "Environmental Issues"
    | "Utilities & Infrastructure"
    | "Public Safety"
    | "Other";
  title: string;
  description: string;
  status?: "Reported" | "In Progress" | "Resolved" | "Rejected" | "Pending";
  location: ILocation;
  media?: number[];
  createdAt?: Date;
  updatedAt?: Date;
  handledBy?: number; 
}
