let Hooks = {}

Hooks.line_graph = {
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
			yaxis: {
				decimalsInFloat: 0
			},
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

		this.handleEvent("toggle-series", payload => {
			chart.toggleSeries(payload.name)
		})
	}
}

Hooks.time_series_graph = {
	mounted() {

		const chartConfig = JSON.parse(this.el.dataset.config)
		const seriesData = JSON.parse(this.el.dataset.series)

		console.log(seriesData)

		const options = {
			chart: Object.assign({
				background: 'transparent',
			}, chartConfig),
			series: seriesData,
			stroke: {
				curve: "smooth"
			},
			markers: {
				size: 6
			},
			legend: {
				show: false
			},
			yaxis: {
				decimalsInFloat: 1
			}
		}

		const chart = new ApexCharts(this.el, options);

		chart.render();

		this.handleEvent("toggle-datapoint", payload => {
			if (payload.index) {
				chart.toggleDataPointSelection(0, payload.index);
				return
			}

			prevSelected = chart.w.globals.selectedDataPoints[0]
			if (prevSelected.length > 0) {
				chart.toggleDataPointSelection(0, prevSelected[0])
				return
			}
		})

		this.handleEvent("update-dataset", data => {
			chart.updateOptions({
				series: data.series
			})
		})

		this.handleEvent("toggle-series", payload => {
			chart.toggleSeries(payload.name)
		})
	}
}
export default Hooks
