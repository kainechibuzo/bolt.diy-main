import { useStore } from '@nanostores/react';
import { ClientOnly } from 'remix-utils/client-only';
import { chatStore } from '~/lib/stores/chat';
import { classNames } from '~/utils/classNames';
import { HeaderActionButtons } from './HeaderActionButtons.client';
import { ChatDescription } from '~/lib/persistence/ChatDescription.client';
import { sidebarStore } from '~/lib/stores/sidebar';

export function Header() {
  const chat = useStore(chatStore);
  const sidebarOpen = useStore(sidebarStore);

  const toggleSidebar = () => {
    sidebarStore.set(!sidebarOpen);
  };

  return (
    <header
      className={classNames('flex items-center px-4 border-b h-[var(--header-height)]', {
        'border-transparent': !chat.started,
        'border-bolt-elements-borderColor': chat.started,
      })}
    >
      <button 
        onClick={toggleSidebar}
        className="flex items-center justify-center w-10 h-10 rounded-lg text-bolt-elements-textPrimary hover:bg-bolt-elements-background-depth-2 transition-colors"
        title="Toggle sidebar"
      >
        <div className="i-ph:sidebar-simple-duotone text-xl" />
      </button>
      <a href="/" className="flex items-center gap-2 z-logo text-bolt-elements-textPrimary ml-2">
        {/* <span className="i-bolt:logo-text?mask w-[46px] inline-block" /> */}
        <img src="/logo-light-styled.png" alt="logo" className="w-[90px] inline-block dark:hidden" />
        <img src="/logo-dark-styled.png" alt="logo" className="w-[90px] inline-block hidden dark:block" />
      </a>
      {chat.started && ( // Display ChatDescription and HeaderActionButtons only when the chat has started.
        <>
          <span className="flex-1 px-4 truncate text-center text-bolt-elements-textPrimary">
            <ClientOnly>{() => <ChatDescription />}</ClientOnly>
          </span>
          <ClientOnly>
            {() => (
              <div className="">
                <HeaderActionButtons chatStarted={chat.started} />
              </div>
            )}
          </ClientOnly>
        </>
      )}
    </header>
  );
}
