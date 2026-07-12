import { useRef, useEffect, useState } from 'react';
import { IconButton } from '~/components/ui/IconButton';
import type React from 'react';

interface ChatOption {
  id: string;
  icon: string;
  title: string;
  onClick: () => void;
  disabled?: boolean;
  isActive?: boolean;
  className?: string;
}

interface ChatOptionsMenuProps {
  options: ChatOption[];
  isOpen: boolean;
  onToggle: (open: boolean) => void;
}

export function ChatOptionsMenu({ options, isOpen, onToggle }: ChatOptionsMenuProps) {
  const menuRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
        onToggle(false);
      }
    }

    if (isOpen) {
      document.addEventListener('mousedown', handleClickOutside);
    }

    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [isOpen, onToggle]);

  return (
    <div ref={menuRef} className="relative">
      <IconButton
        title="More options"
        className="transition-all"
        onClick={() => onToggle(!isOpen)}
      >
        <div className="i-ph:dots-three text-lg"></div>
      </IconButton>

      {isOpen && (
        <div className="absolute bottom-full right-0 mb-2 bg-bolt-elements-background-depth-2 border border-bolt-elements-borderColor rounded-lg shadow-lg p-2 z-50 min-w-max">
          {options.map((option) => (
            <IconButton
              key={option.id}
              title={option.title}
              disabled={option.disabled}
              className={`transition-all w-full justify-start px-3 py-2 text-sm ${
                option.isActive
                  ? '!bg-bolt-elements-item-backgroundAccent !text-bolt-elements-item-contentAccent'
                  : ''
              } ${option.className || ''}`}
              onClick={() => {
                option.onClick();
                onToggle(false);
              }}
            >
              <div className={`${option.icon} text-lg`}></div>
              <span className="ml-2">{option.title}</span>
            </IconButton>
          ))}
        </div>
      )}
    </div>
  );
}
