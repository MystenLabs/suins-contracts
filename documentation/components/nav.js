import { useConfig } from 'nextra-theme-docs';
import Link from 'next/link';

const NavBar = () => {
    const search = useConfig().search.component({className: 'bg-slate-100'});
    const logo = useConfig().logo;
    const themeSwitch = useConfig().themeSwitch.component({lite: false, className: 'bg-white'});

const handleClick = () => {

}

    return (
        <div className="suins-nav-container sticky top-0 w-full bg-blurple z-10">
            <nav className="max-w-[90rem] grid grid-cols-12 h-16 gap-4 items-center">
                <div className="col-span-3" onClick={handleClick}>
                    <Link href="/">
                        <img className="w-4 mx-4 inline" src="/logo.svg"></img>
                        <h1 className="text-white bold inline">{logo}</h1>
                    </Link>
                </div>
                <div className="col-span-5 nav-item-placeholder"></div>
                <div className="col-span-3 flex justify-end">{search}</div>
                <div className="col-span-1 z-50">{themeSwitch}</div>
            </nav>
        </div>
    )
}

export default NavBar;