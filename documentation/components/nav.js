import { useConfig } from 'nextra-theme-docs';
import Link from 'next/link';

const NavBar = () => {
    const search = useConfig().search.component({className: 'bg-slate-100'});
    const logo = useConfig().logo;
    const themeSwitch = useConfig().themeSwitch.component({lite: false, className: 'bg-white'});

    return (
        <div className="suins-nav-container sticky top-0 w-full bg-blurple z-10">
            <nav className="max-w-[110rem] grid grid-cols-12 h-16 gap-4 items-center">
                <div className="col-span-3 ml-2">
                    <Link href="/">
                        <img className="w-4 mx-4 inline" src="/logo.svg"></img>
                        <h1 className="text-white bold hidden lg:inline">{logo}</h1>
                    </Link>
                </div>
                <div className="col-span-9 flex justify-end mr-8 items-center">
                    <ul>
                        <li>
                            <a href="https://suins.io/account/my-names" target="_blank">
                                <span className="external-link text-xs">
                                    <span className='hidden sm:inline'>SuiNS </span>
                                    Dashboard
                                </span>
                            </a>
                        </li>
                    </ul>
                    <div className="mx-4">
                        {search}
                    </div>
                    {themeSwitch}
                </div>
            </nav>
        </div>
    )
}

export default NavBar;