let Hooks = {}

Hooks.Chart = {
	mounted() {
		const chartConfig = JSON.parse(this.el.dataset.config)
		const seriesData = JSON.parse(this.el.dataset.series)
		const categoriesData = JSON.parse(this.el.dataset.categories)

		const options = {
			chart: Object.assign({
				background: 'transparent',
			}, chartConfig),
			series: seriesData,
			xaxis: {
				categories: categoriesData
			},
			stroke: {
				curve: "smooth"
			},
			markers: {
				size: 6
			},
			legend: {
				show: false
			},
			xaxis: {
				range: 10
			},
			yaxis: {
				decimalsInFloat: 0
			},
		}

		const chart = new ApexCharts(this.el, options);

		chart.render();

		console.log("rendered")

		this.handleEvent("update-dataset", data => {
			chart.updateOptions({
				series: data.dataset,
				xaxis: {
					categories: data.categories
				}
			})
		})

		this.handleEvent("toggle-series", payload => {
			chart.toggleSeries(payload.name)
		})
	}
}

export default Hooks
