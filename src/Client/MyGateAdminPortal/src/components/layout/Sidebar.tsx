import { NavLink, useLocation } from 'react-router-dom';
import { LayoutDashboard, Users, Car, Building, FileText, UserPlus } from 'lucide-react'; // Removed 'Settings' and 'React'

const Sidebar = () => {
  const location = useLocation();

   const menuItems = [
    { name: 'Dashboard', path: '/', icon: LayoutDashboard },
    { name: 'Visitors', path: '/visitors', icon: Users },
    { name: 'Notices', path: '/notices', icon: FileText }, // ADDED
    { name: 'Amenities', path: '/amenities', icon: LayoutDashboard }, // ADDED (Using LayoutDashboard as placeholder icon)
      { name: 'Master Data', path: '/master', icon: Building }, // NEW
    { name: 'Vehicles', path: '/vehicles', icon: Car },
    { name: 'Billing', path: '/billing', icon: FileText },
    { name: 'Assign Member', path: '/assign-member', icon: UserPlus },
  ];

  return (
    <div className="w-64 bg-slate-900 text-white h-screen fixed left-0 top-0 flex flex-col">
      <div className="h-16 flex items-center px-6 font-bold text-xl border-b border-slate-700">
        MYGATE <span className="text-blue-500 ml-1">ADMIN</span>
      </div>
      
      <nav className="flex-1 py-4">
        {menuItems.map((item) => {
          const Icon = item.icon;
          const isActive = location.pathname === item.path;
          return (
            <NavLink
              key={item.name}
              to={item.path}
              className={`flex items-center px-6 py-3 transition-colors ${
                isActive ? 'bg-blue-600 text-white border-l-4 border-blue-400' : 'text-slate-400 hover:bg-slate-800 hover:text-white'
              }`}
            >
              <Icon className="w-5 h-5 mr-3" />
              {item.name}
            </NavLink>
          );
        })}
      </nav>
      
      <div className="p-6 text-xs text-slate-500 border-t border-slate-700">
        Ver 2.0.4 (React Build)
      </div>
    </div>
  );
};

export default Sidebar;