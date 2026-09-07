export interface User {
  id: string;
  name: string;
  role: string;
}

export interface Society {
  id: string;
  name: string;
}

export interface Visitor {
  id: number;
  name: string;
  type: string;
  status: 'Pending' | 'Approved' | 'Rejected';
  purpose: string;
}