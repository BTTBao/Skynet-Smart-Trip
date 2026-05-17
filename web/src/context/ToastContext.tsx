import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
  type PropsWithChildren,
} from 'react';

type ToastType = 'success' | 'error' | 'info';

interface ToastItem {
  id: number;
  title: string;
  message?: string;
  type: ToastType;
}

interface ToastPayload {
  title: string;
  message?: string;
  type?: ToastType;
}

interface ToastContextValue {
  showToast: (payload: ToastPayload) => void;
}

const toastStyles: Record<ToastType, { ring: string; iconBg: string; icon: string }> = {
  success: {
    ring: 'ring-primary-container/30',
    iconBg: 'bg-primary-container/15 text-primary-container',
    icon: 'check_circle',
  },
  error: {
    ring: 'ring-error/20',
    iconBg: 'bg-error-container text-error',
    icon: 'error',
  },
  info: {
    ring: 'ring-tertiary/20',
    iconBg: 'bg-tertiary-container/15 text-tertiary',
    icon: 'info',
  },
};

const ToastContext = createContext<ToastContextValue | null>(null);

export function ToastProvider({ children }: PropsWithChildren) {
  const [toasts, setToasts] = useState<ToastItem[]>([]);

  const dismissToast = useCallback((id: number) => {
    setToasts((current) => current.filter((toast) => toast.id !== id));
  }, []);

  const showToast = useCallback(({ title, message, type = 'info' }: ToastPayload) => {
    const id = Date.now() + Math.floor(Math.random() * 1000);
    setToasts((current) => [...current, { id, title, message, type }]);

    window.setTimeout(() => dismissToast(id), 3200);
  }, [dismissToast]);

  const value = useMemo(() => ({ showToast }), [showToast]);

  return (
    <ToastContext.Provider value={value}>
      {children}

      <div className="fixed top-6 right-6 z-[100] flex w-full max-w-sm flex-col gap-3">
        {toasts.map((toast) => {
          const style = toastStyles[toast.type];
          return (
            <div
              key={toast.id}
              className={`rounded-3xl bg-white px-4 py-4 shadow-[0px_20px_40px_rgba(21,28,39,0.12)] ring-1 ${style.ring}`}
            >
              <div className="flex items-start gap-3">
                <div className={`flex h-10 w-10 items-center justify-center rounded-2xl ${style.iconBg}`}>
                  <span className="material-symbols-outlined text-[20px]">{style.icon}</span>
                </div>
                <div className="flex-1">
                  <p className="text-sm font-bold text-on-surface">{toast.title}</p>
                  {toast.message ? (
                    <p className="mt-1 text-xs leading-relaxed text-on-surface-variant">{toast.message}</p>
                  ) : null}
                </div>
                <button
                  onClick={() => dismissToast(toast.id)}
                  className="rounded-full p-1 text-on-surface-variant transition-all hover:bg-surface-container-low"
                >
                  <span className="material-symbols-outlined text-[18px]">close</span>
                </button>
              </div>
            </div>
          );
        })}
      </div>
    </ToastContext.Provider>
  );
}

export function useToast() {
  const context = useContext(ToastContext);

  if (!context) {
    throw new Error('useToast must be used within ToastProvider');
  }

  return context;
}
