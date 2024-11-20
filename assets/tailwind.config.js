// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin")
const fs = require("fs")
const path = require("path")

module.exports = {
	content: [
		"./js/**/*.js",
		"../lib/bodydashboard_web.ex",
		"../lib/bodydashboard_web/**/*.*ex"
	],
	theme: {
		extend: {
			colors: {
				// Primary brand colors
				primary: {
					50: '#e6f5ff',
					100: '#b3e0ff',
					200: '#80ccff',
					300: '#4db8ff',
					400: '#1aa3ff',
					500: '#0088e6', // Main brand color
					600: '#006bb3',
					700: '#004d80',
					800: '#00304d',
					900: '#00121a',
				},
				// Secondary accent color - energetic orange for CTAs and highlights
				accent: {
					50: '#fff3e6',
					100: '#ffddb3',
					200: '#ffc680',
					300: '#ffaf4d',
					400: '#ff991a',
					500: '#ff8c00', // Main accent
					600: '#cc7000',
					700: '#995400',
					800: '#663800',
					900: '#331c00',
				},
				// Success colors for achievements and completed goals
				success: {
					50: '#ecfdf5',
					100: '#d1fae5',
					200: '#a7f3d0',
					300: '#6ee7b7',
					400: '#34d399',
					500: '#10b981', // Main success
					600: '#059669',
					700: '#047857',
					800: '#065f46',
					900: '#064e3b',
				},
				// Warning colors for approaching goals/limits
				warning: {
					50: '#fffbeb',
					100: '#fef3c7',
					200: '#fde68a',
					300: '#fcd34d',
					400: '#fbbf24',
					500: '#f59e0b', // Main warning
					600: '#d97706',
					700: '#b45309',
					800: '#92400e',
					900: '#78350f',
				},
				// Error colors for missed goals or alerts
				error: {
					50: '#fef2f2',
					100: '#fee2e2',
					200: '#fecaca',
					300: '#fca5a5',
					400: '#f87171',
					500: '#ef4444', // Main error
					600: '#dc2626',
					700: '#b91c1c',
					800: '#991b1b',
					900: '#7f1d1d',
				},
				// Neutral colors for text and UI elements
				neutral: {
					50: '#fafafa',
					100: '#f5f5f5',
					200: '#e5e5e5',
					300: '#d4d4d4',
					400: '#a3a3a3',
					500: '#737373', // Main text
					600: '#525252',
					700: '#404040',
					800: '#262626',
					900: '#171717',
				},
			},
		},
	},
	plugins: [
		require("@tailwindcss/forms"),
		// Allows prefixing tailwind classes with LiveView classes to add rules
		// only when LiveView classes are applied, for example:
		//
		//     <div class="phx-click-loading:animate-ping">
		//
		plugin(({ addVariant }) => addVariant("phx-click-loading", [".phx-click-loading&", ".phx-click-loading &"])),
		plugin(({ addVariant }) => addVariant("phx-submit-loading", [".phx-submit-loading&", ".phx-submit-loading &"])),
		plugin(({ addVariant }) => addVariant("phx-change-loading", [".phx-change-loading&", ".phx-change-loading &"])),

		// Embeds Heroicons (https://heroicons.com) into your app.css bundle
		// See your `CoreComponents.icon/1` for more information.
		//
		plugin(function({ matchComponents, theme }) {
			let iconsDir = path.join(__dirname, "../deps/heroicons/optimized")
			let values = {}
			let icons = [
				["", "/24/outline"],
				["-solid", "/24/solid"],
				["-mini", "/20/solid"],
				["-micro", "/16/solid"]
			]
			icons.forEach(([suffix, dir]) => {
				fs.readdirSync(path.join(iconsDir, dir)).forEach(file => {
					let name = path.basename(file, ".svg") + suffix
					values[name] = { name, fullPath: path.join(iconsDir, dir, file) }
				})
			})
			matchComponents({
				"hero": ({ name, fullPath }) => {
					let content = fs.readFileSync(fullPath).toString().replace(/\r?\n|\r/g, "")
					let size = theme("spacing.6")
					if (name.endsWith("-mini")) {
						size = theme("spacing.5")
					} else if (name.endsWith("-micro")) {
						size = theme("spacing.4")
					}
					return {
						[`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
						"-webkit-mask": `var(--hero-${name})`,
						"mask": `var(--hero-${name})`,
						"mask-repeat": "no-repeat",
						"background-color": "currentColor",
						"vertical-align": "middle",
						"display": "inline-block",
						"width": size,
						"height": size
					}
				}
			}, { values })
		})
	]
}
