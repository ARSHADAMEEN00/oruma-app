// Patient Model
export interface Patient {
  id?: string;
  name: string;
  relation: string;
  gender: 'Male' | 'Female' | 'Other';
  address: string;
  phone: string;
  phone2?: string;
  age: number;
  place: string;
  village: string;
  disease: string[];
  plan: string;
  registerId?: string;
  registrationDate?: string; // ISO date string - User-controlled registration date
  isDead?: boolean;
  dateOfDeath?: string; // ISO date string
  createdAt?: Date;
  createdBy?: string;
}

// Visit Mode Enum
export enum VisitMode {
  MONTHLY = 'monthly',
  EMERGENCY = 'emergency',
  NEW = 'new',
  DHC_VISIT = 'dhc_visit',
  VHC_VISIT = 'vhc_visit',
}

// Home Visit Model
export interface HomeVisit {
  id?: string;
  patientName: string;
  address: string;
  visitDate: string; // ISO date string
  visitMode?: VisitMode;
  team?: string;
  notes?: string;
  createdAt?: Date;
  createdBy?: string;
}

// Equipment Model
export interface Equipment {
  id?: string;
  uniqueId: string;      // Unique ID for each individual equipment (e.g., "WH-001")
  serialNo: string;      // Base serial number (e.g., "WH")
  name: string;
  quantity: number;      // Always 1 for individual items
  purchasedFrom: string;
  place: string;
  phone: string;
  storagePlace?: string;
  status?: 'available' | 'supplied' | 'maintenance';  // Track equipment status
  createdAt?: Date;
  createdBy?: string;
}

// Equipment Supply Model - Links equipment to patients
export interface EquipmentSupply {
  id?: string;
  equipmentId: string;        // Reference to Equipment._id
  equipmentUniqueId: string;  // Equipment unique ID (e.g., "WH-001")
  equipmentName: string;      // Equipment name for display
  patientName?: string;
  patientPhone?: string;
  patientAddress?: string;
  careOf?: string;
  receiverName?: string;
  receiverPhone?: string;
  receiverAddress?: string;
  receiverPlace?: string;
  supplyDate: string;         // ISO date string
  returnDate?: string;        // Expected return date (optional)
  actualReturnDate?: string;  // When actually returned
  status: 'active' | 'returned' | 'lost';
  notes?: string;
  returnNote?: string;
  createdAt?: Date;
  updatedAt?: Date;
  createdBy?: string;
}

// Medicine Supply Model
export interface MedicineSupply {
  id?: string;
  patientName: string;
  medicine: string;
  quantity: number;
  phone: string;
  address?: string;
  createdAt?: Date;
  createdBy?: string; // User ID
}

// User Model
export interface User {
  id?: string;
  email: string;
  password?: string; // Hashed reference, not returned in API usually
  name: string;
  role?: 'admin' | 'user';
  createdAt?: Date;
}

