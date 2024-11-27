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
			}
		}

		const chart = new ApexCharts(this.el, options);

		chart.render();

		this.handleEvent("update-dataset", data => {
			chart.updateOptions({
				series: data.dataset,
				xaxis: {
					categories: data.categories
				}
			})
		})
	}
}

export default Hooks
