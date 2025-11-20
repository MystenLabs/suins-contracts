import {useThemeConfig} from '@docusaurus/theme-common';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faGithub, faDiscord, faXTwitter } from '@fortawesome/free-brands-svg-icons';

export default function Footer(): JSX.Element | null {
  const {footer} = useThemeConfig();
  if (!footer) {
    return null;
  }
  const {copyright} = footer;

  return (
    <footer className="bg-suins-purple-darker py-6 border-t border-suins-green-dark">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center flex-wrap gap-2">
          {copyright && (
            <span className="text-suins-white text-sm">
              {copyright}
            </span>
          )}
          <div className="flex gap-4">
          <a 
            href="https://discord.gg/69te6EwCxN"
            target="_blank"
            rel="noopener noreferrer"
            className="!text-suins-white-70 hover:!text-suins-white-100 transition-colors duration-200 flex items-center mr-1"
            aria-label="Join us on Discord"
          >
            <FontAwesomeIcon icon={faDiscord} size="lg" />
          </a>

          <a 
            href="https://twitter.com/suinsdapp"
            target="_blank"
            rel="noopener noreferrer"
            className="!text-suins-white-70 hover:!text-suins-white-100 transition-colors duration-200 flex items-center mr-1"
            aria-label="Follow us on Twitter"
          >
            <FontAwesomeIcon icon={faXTwitter} size="lg" />
          </a>

          <a 
            href="https://github.com/MystenLabs/suins-contracts"
            target="_blank"
            rel="noopener noreferrer"
            className="!text-suins-white-70 hover:!text-suins-white-100 transition-colors duration-200 flex items-center"
            aria-label="View source on GitHub"
          >
            <FontAwesomeIcon icon={faGithub} size="lg" />
          </a>
          </div>
        </div>
      </div>
    </footer>
  );
}